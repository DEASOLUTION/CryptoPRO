# Автоматический скрипт для поиска контейнеров и установки сертификатов

# Функция поиска файлов сертификатов
function Find-CertificateFiles {
    param([string]$DriveLetter)
    
    $certExtensions = @("*.cer", "*.crt", "*.p7b", "*.pfx")
    $foundFiles = @()
    
    foreach ($ext in $certExtensions) {
        $files = Get-ChildItem -Path $DriveLetter -Filter $ext -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            $foundFiles += $files
        }
    }
    
    return $foundFiles
}

# Функция установки сертификата
function Install-Certificate {
    param(
        [string]$Container,
        [array]$CertFiles
    )
    
    foreach ($certFile in $CertFiles) {
        Write-Host "Установка сертификата: $($certFile.Name)" -ForegroundColor Yellow
        Write-Host "В контейнер: $Container" -ForegroundColor Gray
        
        $result = & "C:\Program Files\Crypto Pro\CSP\certmgr.exe" -inst -file "$($certFile.FullName)" -cont "$Container"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Сертификат успешно установлен!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Ошибка установки сертификата! Код: $LASTEXITCODE" -ForegroundColor Red
        }
    }
    
    return $false
}

# Основной код скрипта
Write-Host "Автоматическая установка сертификатов из съемных носителей..." -ForegroundColor Cyan

try {
    # Получаем контейнеры на съемных носителях
    Write-Host "Поиск контейнеров на съемных носителях..." -ForegroundColor Yellow
    $output = & "C:\Program Files\Crypto Pro\CSP\csptest.exe" -keyset -enum_cont -verifycontext -fqcn
    $removableContainers = $output | Where-Object { 
        $_ -like "\\.\*" -and $_ -notlike "\\.\REGISTRY*" -and $_.Trim() -ne ""
    }
    
    if ($removableContainers.Count -eq 0) {
        Write-Host "Контейнеры на съемных носителях не найдены!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Найдено контейнеров: $($removableContainers.Count)" -ForegroundColor Green
    
    # Обрабатываем каждый контейнер
    foreach ($container in $removableContainers) {
        Write-Host "`nОбрабатываем контейнер: $container" -ForegroundColor Cyan
        
        # Извлекаем букву диска из пути контейнера
        if ($container -match '\\\\.\\([A-Za-z0-9_]+)\\') {
            $diskInfo = $matches[1]
            
            # Пытаемся извлечь букву диска (последний символ после _)
            if ($diskInfo -match '([A-Z])_?$') {
                $driveLetter = $matches[1] + ":"
                Write-Host "Определен диск: $driveLetter" -ForegroundColor Yellow
                
                # Ищем сертификаты на этом диске
                $certFiles = Find-CertificateFiles -DriveLetter $driveLetter
                
                if ($certFiles.Count -gt 0) {
                    Install-Certificate -Container $container -CertFiles $certFiles
                } else {
                    Write-Host "На диске $driveLetter не найдены файлы сертификатов" -ForegroundColor Red
                }
            } else {
                Write-Host "Не удалось определить букву диска из: $diskInfo" -ForegroundColor Red
            }
        } else {
            Write-Host "Неверный формат пути контейнера" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nЗавершено!" -ForegroundColor Cyan