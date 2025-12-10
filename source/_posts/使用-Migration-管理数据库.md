---
title: 使用 Migration 管理数据库
tags: '-sql'
abbrlink: 46432
date: 2025-12-05 22:55:29
---

 # 使用 Migration 管理数据库

  使用 ORM 而不是 raw SQL 或 SQL builder 的主要优势之一，就是可以用 ORM 的 migration 管理数据库的升级。

  ## 适用场景

  1. **表结构升级**：数据库需要变化，比如某些表需要新增字段
  2. **多变体应用**：程序需要多种变体，比如金融应用中不同券商需要不同的数据表

  ## 目录结构

  project/
  ├── migrations/
  │   ├── common/                           # 共享基础结构
  │   │   └── 00000000000000_base/
  │   │       ├── up.sql
  │   │       └── down.sql
  │   ├── broker_a/                         # 券商A专用
  │   │   └── 00000000000001_margin_a/
  │   │       ├── up.sql
  │   │       └── down.sql
  │   └── broker_b/                         # 券商B专用
  │       └── 00000000000001_margin_b/
  │           ├── up.sql
  │           └── down.sql
  ├── diesel.toml
  └── .env

  ## Migration 文件结构

  每个 migration 包含两个文件：

  ```sql
  -- up.sql（升级脚本）
  CREATE TABLE users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL
  );

  -- down.sql（回滚脚本）
  DROP TABLE users;

  具体用法（以 diesel_cli 为例）

  安装 diesel_cli

  cargo install diesel_cli --no-default-features --features sqlite

  创建目录

  mkdir -p migrations/common migrations/broker_a migrations/broker_b

  创建共享基础 migration

  diesel migration generate --migration-dir migrations/common create_base_tables

  创建券商专用 migration

  diesel migration generate --migration-dir migrations/broker_a create_margin_accounts
  diesel migration generate --migration-dir migrations/broker_b create_margin_accounts

  运行 migration

  # 先运行共享基础
  diesel migration run --migration-dir migrations/common

  # 再运行特定券商
  diesel migration run --migration-dir migrations/broker_a

  部署脚本

  #!/bin/bash
  # deploy.sh
  set -e

  BROKER=${1:?Usage: ./deploy.sh <broker_a|broker_b>}
  DATABASE_URL=${DATABASE_URL:?DATABASE_URL not set}

  # 清理并准备 migration 目录
  rm -rf migrations/current
  mkdir -p migrations/current

  # 复制共享 + 特定券商的 migrations
  cp -r migrations/common/* migrations/current/
  cp -r migrations/$BROKER/* migrations/current/

  # 运行 migration
  diesel migration run --migration-dir migrations/current

  echo "Done."

  使用：

  ./deploy.sh broker_a

  生成 Schema

  每个券商生成独立的 schema：

  diesel print-schema > src/schema_broker_a.rs

  用 feature 区分（可选）

  // src/schema.rs
  #[cfg(feature = "broker_a")]
  include!("schema_broker_a.rs");

  #[cfg(feature = "broker_b")]
  include!("schema_broker_b.rs");

  ```

| 命令                             | 说明                                   |
| -------------------------------- | -------------------------------------- |
| diesel migration generate <name> | 创建新 migration                       |
| diesel migration run             | 运行所有待执行的 migrations            |
| diesel migration revert          | 回滚最近一次 migration                 |
| diesel migration redo            | 重做最近一次 migration（revert + run） |
| diesel print-schema              | 生成 schema.rs                         |
|                                  |                                        |

