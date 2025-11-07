#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════════"
echo "🚀 Complete Data Lake Workflow"
echo "════════════════════════════════════════════════════════════"
echo ""

# Phase 1: API → Raw Zone → Staging
echo "📥 PHASE 1: Ingestion (API → Raw Zone → Staging)"
echo "────────────────────────────────────────────────────────────"
./scripts/load-data.sh
echo ""

# Phase 2: dbt Transformations
echo "🔄 PHASE 2: Transformation (Staging → Analytics)"
echo "────────────────────────────────────────────────────────────"
./scripts/transform-data.sh
echo ""

# Phase 3: Data Quality Tests
echo "✅ PHASE 3: Data Quality Validation"
echo "────────────────────────────────────────────────────────────"
./scripts/run-tests.sh
echo ""

# Phase 4: Export to Curated Zone
echo "📤 PHASE 4: Export (Analytics → Curated Zone)"
echo "────────────────────────────────────────────────────────────"
./scripts/export-curated.sh
echo ""

# Phase 5: Verification
echo "🔍 PHASE 5: Verification"
echo "────────────────────────────────────────────────────────────"
./scripts/verify-zones.sh
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ Complete Workflow Finished Successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 Data Lake Summary:"
echo "  • Raw Zone: API data stored in Minio"
echo "  • Staging Zone: 37 records in PostgreSQL raw schema"
echo "  • Analytics Zone: 7 models in PostgreSQL analytics schema"
echo "  • Curated Zone: Exported analytics data in Minio"
echo ""
echo "Next steps:"
echo "  • View analysis: ./scripts/run-analysis.sh"
echo "  • Check zones: ./scripts/verify-zones.sh"