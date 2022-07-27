<#
.SYNOPSIS
    Author        :  mind2hex
    Description   :  Simple Powershell Port Scanner
    Language      :  PowerShell 5.1

.DESCRIPTION
    PortScanner.ps1 es un escaner de puertos simple para ejecutarse en una PowerShell.
    Para poder ejecutar este script es necesario establecer la politica de ejecucion como
    RemoteSigned
    C:\> Set-ExecutionPolicy RemoteSigned

.PARAMETER Target
    Es la direccion IPv4 que se va a escanear

.PARAMETER Port
    Es el puerto o rango de puertos [n-n] al que se le van a hacer las pruebas en $Target

.PARAMETER OutputFile
    Especifica el archivo en el que se va a guardar el resultado del escaneo

.PARAMETER Force
    Fuerza el escaneo en caso de que se realice la prueba ping y el $Target no responda

.PARAMETER Timeout
    Especifica el tiempo de duracion de cada prueba que se realice a cada puerto
    El tiemeout por defecto es igual a 10 segundos

.OUTPUTS
    El resultado se muestra solo en pantalla a no ser que se especificque el argumento OutputFile

.LINK
    Test-Connection, Test-NetConnection, System.Net.IP
#>

param(
    [Parameter(Mandatory=$true)][string] $Target,
    [Parameter(Mandatory=$true)] $Port,
    [Parameter()][string] $OutputFile,
    [Parameter()][switch] $Force,
    [Parameter()][int] $Timeout = 10
)

if ($Port.Contains('-')){
    $Port = $Port.Split('-')
}

function Test-Port{
    param(
        [Parameter(Mandatory=$true)][string] $Target,
        [Parameter(Mandatory=$true)][string] $Port,
        [Parameter()][int] $Timeout
    )

    try{
        $client = New-Object System.Net.Sockets.TcpClient
        $iar    = $client.BeginConnect($Target, $Port, $null, $null)
        $wait   = $iar.AsyncWaitHandle.WaitOne($Timeout, $false)

        if (!$wait){
            $client.close()
            return $false

        }else{
            $null = $client.EndConnect($iar)
            $client.Close()
            return $true
        }

    }catch{
        $false
    }
}

#Test-Port -Target $Target -Port $Port -Timoeut $Timeout

# Verificando que el server este conectado...
if ($Force -eq $false){
    Write-Output "[*] Verificando que el target $Target este activo..."
    $result = Test-Connection $Target -Quiet -Count 2 -BufferSize 32

    if ($result -eq $false){
        Write-Warning "El target $Target no se encuentra activo, finalizando programa..."    
        exit
        }
}else{
    Write-Warning "Escanear una computadora inactiva podria hacer que el escaneo tarde demasiado..."
}


# Iterando puertos para escanear
foreach ($i in ($Port[0]..$Port[1])) {
    $PercentCompleted = ($i/($Port[0]..$Port[1]).Length*100)
    Write-Progress -Activity "Escaneando puertos..." -Status "$PercentCompleted% Completado:" -PercentComplete $PercentCompleted
    
    if ((Test-Port -Target $Target -Port $i -Timeout $Timeout) -eq $true){
        Write-Output "[*] Puerto abierto: $i"
    }
}

