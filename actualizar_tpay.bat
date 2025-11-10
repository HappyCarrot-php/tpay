@echo off
cd /d "C:\Users\ricky\Documents\Programacion\Flutter\tpay"

echo ============================
echo   ACTUALIZANDO TPay GIT
echo ============================

git add .
git commit -m "Actualizacion automatica"
git pull
git push

echo ----------------------------
echo   ✅ Todo actualizado!
echo ----------------------------
pause
