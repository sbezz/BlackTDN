#file:srb-split.ps1
#Author:Marinaldo de Jesus
#date:2016-03-04
#Use:1) Ordenar o arquivo de saída do sistema Senior
#    2) Dividir o arquivo gerando os dados por Filial
#    3) Separar em Canais Válidos

#Define o Nome do Arquivo Gerado pelo Senior
Function srb-split
{
    [CmdletBinding(
                    SupportsShouldProcess=$True,
                    ConfirmImpact="Low"
                  )
    ]
    Param(
            [Parameter(Mandatory=$True,Position=1)]
            [string]$filePath="srb.txt"
    )

    Clear-Host
    
    $txtFile=$filePath
    $fName=[System.IO.Path]::GetFileNameWithoutExtension($txtFile)
    $txtSort=$txtFile.Replace($fName,"$($fName)-sort")

    #Obtém o Conteúdo do Arquivo
    #Ordena as Informações
    #Salva o Novo Arquivo
    $MC=Measure-Command {
        $sortFile=Get-Content $txtFile `
            | Show-Progress -Activity "Sorting..."`
            | Sort-Object `
            | Show-Progress -Activity "Saving..."`
            | Out-File -FilePath $txtSort -Encoding ascii -Force
    }

    for($i=1
        $i -le 20
        $i++){
       Write-Host ""
    }

    $MC    

    $MC=Measure-Command {    
    
        #Define o Path para a Gravação dos Arquivos
        $pathOutFile=".\split\srb\"

        #Obtém o Conteúdo do Arquivo Ordenado
        $sortFile=Get-Content $txtSort

        #Força a Criação do Diretório Split a partir de .\
        New-Item -path $pathOutFile -type directory -Force

        #Remove qualquer item existente em .\split
        Remove-Item -Path "$pathOutFile\*" -Force -Recurse

        #Define a HashTable com os Canais
        $Canais=@{
                    SRA="SRA";
                    SRB="SRB"
        }

        #Define o Array com as Filiais
        $Filiais=@("0101","0102","0103","0104","0105","9801")

        #Define bgColor
        $bgColor="Black"

        #Define fgColor
        $fgColor="DarkRed"

        #Define variável para controle de alteração da cor
        $bChgColor=$True

        #Define separador
        $cSep="--------------------------------------------------------------------------"

        $FilePath=""

        Write-Host $cSep -foregroundcolor yellow -backgroundcolor $bgColor

        [int]$nPercentF=0
        [int]$nProgressF=0

        #Lê o conteúdo do arquivo e gera um novo arquivo por Filial
        foreach ($Filial in $Filiais) {

            $key=""
            $lKey=""

            $nProgressF++
            $nPercentF=[int](($nProgressF/$Filiais.Count)*100)

            Write-Progress -id 0 `
                           -Activity "Processando Filial[$Filial]/[$($Filiais)]" `
                           -PercentComplete "$nPercentF" `
                           -Status ("Working["+($nPercentF)+"]%")

            [int]$nPercentC=0
            [int]$nProgressC=0
            
            #Processa para cada CANAL
            foreach ($Canal in $Canais.Values | Sort-Object )
            {
                Write-Host $Filial,$Canal
                Write-Host $cSep -foregroundcolor yellow -backgroundcolor $bgColor

                #Incrementa o Progresso
                $nProgressC++
                $nPercentC=[int](($nProgressC/$Canais.Count)*100)
                Write-Progress -id 1 `
                               -Activity "Processando Canal[$Canal]" `
                               -PercentComplete "$nPercentC" `
                               -Status ("Working["+($nPercentC)+"]%")
                
                #Gera o arquivo por Filial e Canal
                $sortFile | ? {$_.Substring(0,4).Contains($Filial) -and $_.Substring(12,3).Contains($Canal) } | ? {
                        #Obtém a chave para pesquisa
                        if ($Canal.Contains("SRA")){
                            $key=$_.Substring(0,15)
                        } else {
                            $key=$_.Substring(0,18)
                        }
                        #Verifica se é igual a última chave utilizada
                        if ($key -eq $lKey){
                            #Define o arquivo para dados duplicados
                            $FilePath="$($pathOutFile)dupl-srb-$($Filial)-$($Canal).txt"
                        } else {
                            #Define o arquivo para dados OK
                            $FilePath="$($pathOutFile)srb-$($Filial)-$($Canal).txt"
                        }
                        #Grava os Dados no novo arquivo
                        Out-File -inputobject $_ -FilePath $FilePath -Encoding ascii -Append
                        #Salva a última chave utilizada
                        $lKey=$key
                }

                #Obtem o conteúdo para o CANAL
                $FilePath="$($pathOutFile)srb-$($Filial)-$($Canais[$Canal]).txt"
                if (Test-Path $FilePath ){
                    $Content=(Get-Content $FilePath | Where-Object {$_.Substring(12,3).Contains($Canais[$Canal])})
                    if ($Content){
                        [System.Collections.ArrayList]$tmp=@($Content)
                        Set-Variable -Name "t_$Canal" -Value $tmp
                        #Remove o Arquivo de Trabalho
                        Remove-Item $FilePath -Force            
                    }    
                }
                
            }

            [int]$nPercentD=0
            [int]$nProgressD=0

            $bWriteHost=$False
            
            #Processa a partir do CANAL sra
            ($t_sra) | Foreach-Object {$index=0 }{
                Try
                {
                
                    $nProgressD++
                    $nPercentD=[int](($nProgressD/($t_sra).Count)*100)
                    Write-Progress -id 2 `
                                   -Activity "Processando Filial[$Filial]" `
                                   -PercentComplete "$nPercentD" `
                                   -Status ("Working["+($nPercentD)+"]%")
                
                    $key=$t_sra.Item($index).Substring(4,8)

                    if ($srb=$t_srb | Where-Object {$_.Substring(4,8).Contains($key)})
                    {

                        if ($bWriteHost){
                            Write-Host $_   -foregroundcolor $fgColor -backgroundcolor $bgColor
                            Write-Host $srb -foregroundcolor $fgColor -backgroundcolor $bgColor
                        }
                        
                        $FilePath="$($pathOutFile)srb-$($Filial)-Channels-0-1.txt"

                        Out-File -inputobject $_   -FilePath $FilePath -Encoding ascii -Append
                        Out-File -inputobject $srb -FilePath $FilePath -Encoding ascii -Append

                        $t_srb.Remove($srb)

                    } else {
                        
                        if ($bWriteHost){
                            Write-Host $_   -foregroundcolor $fgColor -backgroundcolor $bgColor
                        }    
                      
                        $FilePath="$($pathOutFile)srb-$($Filial)-Channels-0.txt"

                        Out-File -inputobject $_   -FilePath $FilePath -Encoding ascii -Append
                        
                    }

                }
                Catch
                {
                    Write-Host $_.Exception.Message -foregroundcolor red -backgroundcolor yellow
                }
                Finally
                {
                    #...
                }

                $index++

                if ($bChgColor) {
                    $fgColor="White"
                }
                else {
                    $fgColor="DarkRed"
                }

                $bChgColor= -not($bChgColor)

                if ($bWriteHost){                
                    Write-Host $cSep -foregroundcolor yellow -backgroundcolor $bgColor
                }

            }

        }

    }


    Clear-Host

    for($i=1
        $i -le 20
        $i++){
       Write-Host ""
    }

    $MC
    
}
Function Show-Progress{
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,
        [string]$Activity = "Processing items"
    )

    Begin {$PipeArray = @()}

    Process {$PipeArray+=$InputObject}

    End {
        [int]$TotItems = ($PipeArray).Count
        [int]$Count = 0

        $PipeArray|foreach {
            $_
            $Count++
            [int]$percentComplete = [int](($Count/$TotItems* 100))
            Write-Progress -Activity "$Activity" -PercentComplete "$percentComplete" -Status ("Working - " + $percentComplete + "%")
            }
        }
}    
srb-split "srb.txt"
