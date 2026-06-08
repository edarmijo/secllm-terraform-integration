@echo off
chcp 65001 >nul
color 0A
title Pipeline Nocturno IaC-Eval + SecLLM

echo =======================================================
echo   PIPELINE NOCTURNO  IaC-Eval + SecLLM (auto-auditoria)
echo =======================================================
echo.
echo   Para cada modelo:
echo     1) Genera codigo Terraform
echo     2) Lo evalua funcionalmente (terraform plan + OPA)
echo     3) El MISMO modelo lo audita con SecLLM (8 reglas)
echo.
echo   Es resumible: si se corta, vuelve a ejecutar este .bat
echo   y continua donde quedo. Configura modelos y numero de
echo   preguntas en scripts\pipeline.py
echo =======================================================
echo.

REM Ubicarse en la carpeta de este .bat (integration\)
cd /d "%~dp0"

REM Ejecutar el pipeline
python scripts\pipeline.py

echo.
echo Generando reporte comparativo...
python scripts\generate_report.py

echo.
echo =======================================================
echo   PROCESO FINALIZADO
echo   Revisa: outputs\REPORTE_COMPARATIVO.md
echo =======================================================
pause
