# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-10-06

### Changed
- `start-saltminer-data-pipeline.ps1` to use `3.0.0`
- CHANGELOG formating

## 0.5.0 - 2026-10-06

### Changed
- `start-saltminer-data-pipeline.ps1` to v2.1.0
- `start-session-login.ps1` to run uiath bot with login + keep-alive


## 0.4.2 - 2026-10-05

### Fixed
- Automation name in `start-session-login.ps1`
- `start-issues-and-maps-flow.ps1` 0.2.0 version

## 0.4.1 - 2026-10-01

### Added
- `start-session-login.ps1` wrapper to run Archer `login_setup.py` at log on; README schtasks ONLOGON example

## 0.3.1 - 2026-09-30

### Added
- Log forwarder script + rename saltminer data pipeline

## 0.2.1 - 2026-09-30

### Fixed
- Command example in README to use env vars instead of hardcoded user profile path

## 0.2.0 - 2026-09-30

### Added
- Start Issues and MAPs flow batch file

## 0.1.0 - 2026-09-26

### Added
- Start P0 vulnerabilty management pipeline batch file
- Start Saltminer data pipeline batch file
- Instructions for creating, running, viewing and deleting scheduled tasks in README

## 0.0.1 - 2026-09-24

### Added

- Initial project template: source layout, test scaffolding, CI-CD
  workflows, and contributor documentation.

