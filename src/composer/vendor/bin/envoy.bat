@ECHO OFF
setlocal DISABLEDELAYEDEXPANSION
SET BIN_TARGET=%~dp0/../laravel/envoy/envoy
php "%BIN_TARGET%" %*
