@echo off
cd /d "C:\Users\ricky\Documents\Programacion\Flutter\tpay"

echo ============================
echo   ACTUALIZANDO TPay GIT
echo ============================
echo.

set /p mensaje="Escribe el mensaje del commit (o presiona Enter para 'update'): "

if "%mensaje%"==" " set mensaje=update
if "%mensaje%"=="" set mensaje=update

echo.
echo Agregando archivos...
git add .

echo Haciendo commit con mensaje: %mensaje%
git commit -m "%mensaje%"

echo Sincronizando con repositorio remoto...
git pull
git push

echo.
echo ----------------------------
echo   ✅ Todo actualizado!
echo ----------------------------
pause
