# Quotation template continuation pages

Quotation PDF rendering uses the persisted `DocumentPrintTemplate` JSON as its single source of truth. The first page renders every visible saved shape, including page settings, background, border, header, customer/document fields, line table, totals, terms, banking and signatures.

For non-empty `quotation_content`, export-time rendering deep-clones that JSON for each continuation page (`DocumentPrintTemplate.fromJson(template.toJson())`). The clone preserves page dimensions, orientation, font, background and optional outer border, but removes all quotation chrome (header, party data, tables, totals, terms, banking and signatures). It places markdown directly in a clean body area without a repeated quotation heading. The editable base template is never modified or saved.

Markdown supports headings, bullets, numbered items, bold and italic spans, line breaks and blank-line spacing. Blocks are estimated against the available body height so long content flows to additional template-backed pages without covering footer/signature areas.

Preview, Download PDF and Print all use the same vector PDF builder, ensuring identical continuation-page styling. Empty content creates no continuation pages and the existing first-page layout is unchanged.
