# E-Commerce Customer Intelligence & Analytics Pipeline

Production-grade data lake for customer segmentation and retail analytics.

##  Features

- **Customer Segmentation**: RFM analysis with 9 distinct segments
- **Product Intelligence**: Rankings, tiers, and category performance
- **Sales Analytics**: Daily aggregations with trend analysis
- **Quality Assurance**: 26 automated tests + monitoring
- **CI/CD**: Automated GitLab pipeline with 4 stages

##  Architecture
```
API → Raw Zone (MinIO) → Staging (PostgreSQL) → Analytics (dbt) → Curated
```

**Stack:**
- Kubernetes (k3d)
- Apache Airflow 2.8.0
- dbt 1.9.0
- PostgreSQL 15
- MinIO

##  Quick Start

### Local Development
```bash
# 1. Create k3d cluster
k3d cluster create pipeline --agents 2

# 2. Setup infrastructure
./scripts/setup.sh

# 3. Run pipeline
./scripts/run-complete-workflow.sh
```

### CI/CD Pipeline

The GitLab CI/CD pipeline automatically:
1. **Build**: Docker images for data-export and dbt
2. **Test**: dbt compilation and parsing
3. **Deploy**: Kubernetes infrastructure and images
4. **Transform**: Data loading, dbt run, dbt test, dbt docs

**Stages:**
- `build` - Build Docker images
- `test` - Validate dbt project
- `deploy` - Deploy to Kubernetes
- `transform` - Run data pipeline

##  dbt Models

**6 Models:**
- `dim_products` - Product catalog
- `dim_users` - Customer profiles
- `dim_user_segments` - RFM segmentation (⭐ star feature)
- `fct_carts` - Shopping cart transactions
- `fct_daily_sales` - Daily aggregated metrics (incremental)
- `fct_category_performance` - Category analytics

**4 Macros:**
- `generate_timestamp_column()` - Audit timestamps
- `calculate_rfm_score()` - RFM scoring logic
- `cents_to_dollars()` - Currency conversion
- `generate_audit_columns()` - Full audit trail

##  Testing
```bash
# Run all tests (26 tests)
./scripts/run-tests.sh

# Run specific model tests
./scripts/run-dbt.sh "test --select dim_user_segments"
```

##  Analytics Capabilities

### Customer Segmentation
- Champions, Loyal Customers, Potential Loyalists
- New Customers, Promising, At Risk
- Can't Lose Them, Hibernating, Lost

### Business Metrics
- Daily sales volume and trends
- Customer lifetime value
- Category performance
- Product rankings

##  Project Structure
```
.
├── .gitlab-ci.yml          # CI/CD pipeline configuration
├── data-export/            # Python app for API extraction
├── dbt-project/            # dbt transformations
│   ├── models/            # 6 analytical models
│   ├── macros/            # 4 reusable macros
│   └── tests/             # Custom data quality tests
├── kubernetes/            # K8s manifests
│   ├── namespace.yaml
│   ├── postgresql.yaml
│   ├── minio.yaml
│   └── airflow.yaml
└── scripts/               # Helper scripts
```

##  Secrets Management

Secrets are managed via Kubernetes Secrets:
- `postgres-secret` - Database credentials
- `minio-secret` - Object storage credentials

##  Documentation

Generate dbt documentation:
```bash
./scripts/run-dbt.sh "docs generate"
./scripts/run-dbt.sh "docs serve"
```

Or access via CI/CD artifacts after pipeline run.

## 🎓 Key Metrics

- **6 dbt models** (3 dimensions + 3 facts)
- **4 reusable macros** (20% code reduction)
- **26 automated tests** (100% passing)
- **9 customer segments** (RFM-based)
- **4-zone data lake** (medallion architecture)

---
