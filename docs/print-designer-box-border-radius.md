# Print Designer Box Border Radius

The print designer exposes **Border Radius** for Rectangle, Text, Table, and
Barcode shapes. The saved value is applied to the on-screen design preview and
the generated PDF. Negative values are clamped to zero.

No API or database schema change is required: `borderRadius` is an existing
template property.

