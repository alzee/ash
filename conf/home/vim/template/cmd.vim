@echo off

call :f

exit /b

:f
echo this is a
exit /b %errorlevel%
