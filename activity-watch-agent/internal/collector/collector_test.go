package collector

import "testing"

func TestClassifyApplicationUsesExecutableNameOnly(t *testing.T) {
	tests := map[string]string{
		"Google Chrome.app": "browser",
		"Code.exe":          "development",
		"Slack":             "communication",
		"unknown-tool":      "unclassified",
	}
	for name, expected := range tests {
		if actual := ClassifyApplication(name); actual != expected {
			t.Fatalf("ClassifyApplication(%q) = %q, want %q", name, actual, expected)
		}
	}
}

func TestCanonicalItemsDeduplicatesAndSorts(t *testing.T) {
	items := canonicalItems([]string{"zeta", "Alpha", "alpha", ""}, false)
	if len(items) != 2 || items[0].Name != "alpha" || items[1].Name != "zeta" {
		t.Fatalf("items = %#v", items)
	}
}

func TestLaunchdItemsUsesLabelsNotProcessIdentifiers(t *testing.T) {
	items := launchdItems([]string{"PID Status Label", "123 0 com.example.worker", "- 0 com.example.timer"})
	if len(items) != 2 || items[0].Name != "com.example.timer" || items[1].Name != "com.example.worker" {
		t.Fatalf("items = %#v", items)
	}
}
