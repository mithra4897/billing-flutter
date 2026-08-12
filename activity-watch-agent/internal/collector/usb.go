package collector

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"path/filepath"
	"sort"
	"strings"
	"time"
	"unicode/utf16"
)

const maxUSBFilesPerScan = 5000
const maxUSBEventsPerObservation = 50

type USBDevice struct {
	Fingerprint             string `json:"fingerprint"`
	Name                    string `json:"name"`
	Manufacturer            string `json:"manufacturer,omitempty"`
	DriveLetter             string `json:"drive_letter,omitempty"`
	VolumeLabel             string `json:"volume_label,omitempty"`
	CapacityBytes           int64  `json:"capacity_bytes,omitempty"`
	FreeBytes               int64  `json:"free_bytes,omitempty"`
	ConnectedAtUTC          string `json:"connected_at_utc"`
	ObservedAtUTC           string `json:"observed_at_utc"`
	ObservedDurationSeconds int64  `json:"observed_duration_seconds"`
	Connected               bool   `json:"connected"`
}

type USBFile struct {
	DeviceFingerprint string `json:"device_fingerprint"`
	DriveLetter       string `json:"drive_letter"`
	RelativePath      string `json:"relative_path"`
	Name              string `json:"name"`
	Extension         string `json:"extension,omitempty"`
	SizeBytes         int64  `json:"size_bytes,omitempty"`
	ModifiedAtUTC     string `json:"modified_at_utc,omitempty"`
}

type USBFileEvent struct {
	Operation         string `json:"operation"`
	DeviceFingerprint string `json:"device_fingerprint"`
	DriveLetter       string `json:"drive_letter"`
	RelativePath      string `json:"relative_path"`
	Name              string `json:"name"`
	Extension         string `json:"extension,omitempty"`
	SizeBytes         int64  `json:"size_bytes,omitempty"`
	ObservedAtUTC     string `json:"observed_at_utc"`
}

type USBObservation struct {
	TotalPorts     int            `json:"total_ports"`
	UsedPorts      int            `json:"used_ports"`
	Devices        []USBDevice    `json:"devices"`
	FileEvents     []USBFileEvent `json:"file_events"`
	FilesTruncated bool           `json:"files_truncated"`
	ObservedAtUTC  string         `json:"observed_at_utc"`
}

type rawUSBObservation struct {
	TotalPorts int `json:"total_ports"`
	UsedPorts  int `json:"used_ports"`
	Devices    []struct {
		ID           string `json:"id"`
		Name         string `json:"name"`
		Manufacturer string `json:"manufacturer"`
	} `json:"devices"`
	Drives []struct {
		DriveLetter   string `json:"drive_letter"`
		VolumeLabel   string `json:"volume_label"`
		CapacityBytes int64  `json:"capacity_bytes"`
		FreeBytes     int64  `json:"free_bytes"`
	} `json:"drives"`
	Files []struct {
		DriveLetter   string `json:"drive_letter"`
		RelativePath  string `json:"relative_path"`
		SizeBytes     int64  `json:"size_bytes"`
		ModifiedAtUTC string `json:"modified_at_utc"`
	} `json:"files"`
	FilesTruncated bool `json:"files_truncated"`
}

// ObserveUSB returns metadata only. The PowerShell query enumerates names and
// sizes but never opens a removable-drive file or computes a content hash.
func (o *OSObserver) ObserveUSB(ctx context.Context, at time.Time) (USBObservation, error) {
	result := USBObservation{Devices: []USBDevice{}, FileEvents: []USBFileEvent{}, ObservedAtUTC: at.UTC().Format(time.RFC3339Nano)}
	if o.goos != "windows" {
		return result, nil
	}
	var output []byte
	var err error
	encodedScript := encodePowerShellCommand(windowsUSBScript)
	if runner, ok := o.runner.(timeoutCommandRunner); ok {
		output, err = runner.OutputWithTimeout(ctx, 20*time.Second, "powershell.exe", "-NoProfile", "-NonInteractive", "-EncodedCommand", encodedScript)
	} else {
		output, err = o.runner.Output(ctx, "powershell.exe", "-NoProfile", "-NonInteractive", "-EncodedCommand", encodedScript)
	}
	if err != nil {
		return result, err
	}
	var raw rawUSBObservation
	if err := json.Unmarshal(output, &raw); err != nil {
		return result, errors.New("decode Windows USB metadata")
	}
	result.TotalPorts = max(raw.TotalPorts, 0)
	result.UsedPorts = max(raw.UsedPorts, 0)
	result.FilesTruncated = raw.FilesTruncated

	o.usbMu.Lock()
	defer o.usbMu.Unlock()
	if o.usbFiles == nil {
		o.usbFiles = map[string]USBFile{}
		o.usbDevices = map[string]USBDevice{}
		o.usbConnectedAt = map[string]time.Time{}
	}
	currentDevices := make(map[string]USBDevice, len(raw.Devices)+len(raw.Drives))
	driveFingerprints := make(map[string]string, len(raw.Drives))
	previousDrives := make(map[string]struct{})
	for _, device := range o.usbDevices {
		if device.DriveLetter != "" {
			previousDrives[device.DriveLetter] = struct{}{}
		}
	}
	for _, item := range raw.Devices {
		name := boundedText(item.Name, 160)
		if name == "" {
			continue
		}
		fingerprint := usbFingerprint(item.ID, name)
		currentDevices[fingerprint] = USBDevice{Fingerprint: fingerprint, Name: name, Manufacturer: boundedText(item.Manufacturer, 120), Connected: true}
	}
	for _, drive := range raw.Drives {
		letter := strings.ToUpper(strings.TrimSpace(drive.DriveLetter))
		if letter == "" {
			continue
		}
		fingerprint := usbFingerprint("volume:"+letter+":"+drive.VolumeLabel, letter)
		driveFingerprints[letter] = fingerprint
		name := boundedText(drive.VolumeLabel, 160)
		if name == "" {
			name = "Removable drive " + letter
		}
		currentDevices[fingerprint] = USBDevice{Fingerprint: fingerprint, Name: name, DriveLetter: letter, VolumeLabel: boundedText(drive.VolumeLabel, 160), CapacityBytes: max(drive.CapacityBytes, 0), FreeBytes: max(drive.FreeBytes, 0), Connected: true}
	}
	for fingerprint, device := range currentDevices {
		connectedAt, found := o.usbConnectedAt[fingerprint]
		if !found {
			connectedAt = at.UTC()
			o.usbConnectedAt[fingerprint] = connectedAt
		}
		device.ConnectedAtUTC = connectedAt.Format(time.RFC3339Nano)
		device.ObservedAtUTC = at.UTC().Format(time.RFC3339Nano)
		device.ObservedDurationSeconds = max(int64(at.UTC().Sub(connectedAt)/time.Second), 0)
		currentDevices[fingerprint] = device
		result.Devices = append(result.Devices, device)
	}
	for fingerprint, previous := range o.usbDevices {
		if _, connected := currentDevices[fingerprint]; connected {
			continue
		}
		connectedAt := o.usbConnectedAt[fingerprint]
		previous.Connected = false
		previous.ObservedAtUTC = at.UTC().Format(time.RFC3339Nano)
		previous.ObservedDurationSeconds = max(int64(at.UTC().Sub(connectedAt)/time.Second), 0)
		result.Devices = append(result.Devices, previous)
		delete(o.usbConnectedAt, fingerprint)
	}
	sort.Slice(result.Devices, func(i, j int) bool { return result.Devices[i].Name < result.Devices[j].Name })
	if len(result.Devices) > 50 {
		result.Devices = result.Devices[:50]
		result.FilesTruncated = true
	}

	currentFiles := make(map[string]USBFile, min(len(raw.Files), maxUSBFilesPerScan))
	for index, item := range raw.Files {
		if index >= maxUSBFilesPerScan {
			result.FilesTruncated = true
			break
		}
		letter := strings.ToUpper(strings.TrimSpace(item.DriveLetter))
		relative := boundedText(strings.ReplaceAll(item.RelativePath, "\\", "/"), 512)
		if letter == "" || relative == "" {
			continue
		}
		fingerprint := driveFingerprints[letter]
		if fingerprint == "" {
			fingerprint = usbFingerprint("volume:"+letter, letter)
		}
		file := USBFile{DeviceFingerprint: fingerprint, DriveLetter: letter, RelativePath: relative, Name: boundedText(filepath.Base(relative), 255), Extension: boundedText(strings.TrimPrefix(filepath.Ext(relative), "."), 32), SizeBytes: max(item.SizeBytes, 0), ModifiedAtUTC: item.ModifiedAtUTC}
		currentFiles[letter+"|"+strings.ToLower(relative)] = file
	}
	if o.hasUSBBaseline {
		for key, file := range currentFiles {
			_, drivePreviouslyObserved := previousDrives[file.DriveLetter]
			if _, found := o.usbFiles[key]; !found && drivePreviouslyObserved {
				result.FileEvents = append(result.FileEvents, usbFileEvent("added", file, at))
			}
		}
		for key, file := range o.usbFiles {
			_, driveStillConnected := driveFingerprints[file.DriveLetter]
			if _, found := currentFiles[key]; !found && driveStillConnected {
				result.FileEvents = append(result.FileEvents, usbFileEvent("deleted", file, at))
			}
		}
	}
	sort.Slice(result.FileEvents, func(i, j int) bool {
		return result.FileEvents[i].DriveLetter+result.FileEvents[i].RelativePath < result.FileEvents[j].DriveLetter+result.FileEvents[j].RelativePath
	})
	if len(result.FileEvents) > maxUSBEventsPerObservation {
		result.FileEvents = result.FileEvents[:maxUSBEventsPerObservation]
		result.FilesTruncated = true
	}
	o.usbFiles, o.usbDevices, o.hasUSBBaseline = currentFiles, currentDevices, true
	return result, nil
}

// encodePowerShellCommand uses PowerShell's UTF-16LE EncodedCommand contract.
// This avoids Windows command-line reconstruction changing quotes inside WMI
// filters before PowerShell parses the script.
func encodePowerShellCommand(script string) string {
	units := utf16.Encode([]rune(script))
	bytes := make([]byte, len(units)*2)
	for index, unit := range units {
		binary.LittleEndian.PutUint16(bytes[index*2:], unit)
	}
	return base64.StdEncoding.EncodeToString(bytes)
}

func usbFileEvent(operation string, file USBFile, at time.Time) USBFileEvent {
	return USBFileEvent{Operation: operation, DeviceFingerprint: file.DeviceFingerprint, DriveLetter: file.DriveLetter, RelativePath: file.RelativePath, Name: file.Name, Extension: file.Extension, SizeBytes: file.SizeBytes, ObservedAtUTC: at.UTC().Format(time.RFC3339Nano)}
}

func usbFingerprint(identity, fallback string) string {
	value := strings.ToLower(strings.TrimSpace(identity))
	if value == "" {
		value = strings.ToLower(strings.TrimSpace(fallback))
	}
	digest := sha256.Sum256([]byte(value))
	return hex.EncodeToString(digest[:16])
}

func boundedText(value string, limit int) string {
	value = strings.TrimSpace(value)
	runes := []rune(value)
	if len(runes) > limit {
		return string(runes[:limit])
	}
	return value
}

const windowsUSBScript = `$ErrorActionPreference='Stop';$hubs=@(Get-CimInstance Win32_USBHub -ErrorAction SilentlyContinue);$entities=@(Get-CimInstance Win32_PnPEntity -Filter "PNPDeviceID LIKE 'USB%'" -ErrorAction SilentlyContinue | Where-Object {$_.Name -and $_.PNPDeviceID -notmatch 'ROOT_HUB|USB\\ROOT'});$drives=@(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue);$files=New-Object System.Collections.Generic.List[object];$truncated=$false;foreach($d in $drives){$root=$d.DeviceID+'\\';foreach($f in @(Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 5001)){if($files.Count -ge 5000){$truncated=$true;break};$files.Add([pscustomobject]@{drive_letter=$d.DeviceID;relative_path=$f.FullName.Substring($root.Length);size_bytes=[int64]$f.Length;modified_at_utc=$f.LastWriteTimeUtc.ToString('o')})}};$total=0;foreach($h in $hubs){if($h.NumberOfPorts -gt 0){$total+=[int]$h.NumberOfPorts}};[pscustomobject]@{total_ports=$total;used_ports=$entities.Count;devices=@($entities|ForEach-Object{[pscustomobject]@{id=$_.PNPDeviceID;name=$_.Name;manufacturer=$_.Manufacturer}});drives=@($drives|ForEach-Object{[pscustomobject]@{drive_letter=$_.DeviceID;volume_label=$_.VolumeName;capacity_bytes=[int64]$_.Size;free_bytes=[int64]$_.FreeSpace}});files=@($files.ToArray());files_truncated=$truncated}|ConvertTo-Json -Depth 5 -Compress`
