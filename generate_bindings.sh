#!/bin/bash

echo "=== Clean environment ==="
rm -rf lib/pdfbox_bindings/
rm -rf src/pdfbox/
rm -rf mvn_java/

echo "=== Creating summary directory ==="
mkdir -p mvn_java

echo "=== Generate API summary manually ==="
java -cp ".dart_tool/jnigen/ApiSummarizer.jar:jars/pdfbox-3.0.5.jar:jars/fontbox-3.0.5.jar" com.github.dart_lang.jnigen.apisummarizer.Main org.apache.pdfbox.pdmodel.PDDocument org.apache.pdfbox.pdmodel.PDPage org.apache.pdfbox.pdmodel.PDPageTree org.apache.pdfbox.pdmodel.common.PDRectangle > summary.json

echo "=== Place summary in expected location ==="
mkdir -p mvn_java
mv summary.json mvn_java/

echo "=== Verify summary ==="
if [ -f "mvn_java/summary.json" ]; then
    echo "Summary generated successfully!"
    echo "Summary size: $(wc -c < mvn_java/summary.json) bytes"
else
    echo "Error: Summary not found!"
    exit 1
fi

echo "=== Create minimal jnigen.yaml ==="
cat > jnigen_final.yaml << 'EOF'
output:
  dart:
    path: lib/pdfbox_bindings/
  c:
    path: src/pdfbox/

android:
  build: false

classes:
  - org.apache.pdfbox.pdmodel.PDDocument
  - org.apache.pdfbox.pdmodel.PDPage
  - org.apache.pdfbox.pdmodel.PDPageTree
  - org.apache.pdfbox.pdmodel.common.PDRectangle
EOF

echo "=== Generate Dart bindings ==="
dart run jnigen --config jnigen_final.yaml

echo "=== Done! ==="
echo "Check lib/pdfbox_bindings/ for generated Dart files"