@echo off
git add .
git commit -m "Add iOS app with scheme"
git push --set-upstream origin main
echo.
echo Done! Check GitHub Actions now
pause
