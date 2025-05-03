<#
.SYNOPSIS
    Script del ejercicio 5 de la APL 1.
.DESCRIPTION
    Facilita la consulta de informacion relacionada a los nutrientes
    de las frutas a travez de la Api Fruityvice. Se recibe los ids o
    nombres de las frutas y se muestra por pantalla su informacion
.INPUTS
    numeros enteros positivos o
    cadenas
.OUTPUTS
        id: 2,
        name: Orange,
        genus: Citrus,
        calories: 43,
        fat: 0.2,
        sugar: 8.2,
        carbohydrates: 8.3,
        protein: 1
.PARAMETER id
    Valor o valores enteros para identificar la fruta que se quiere consultar.
.PARAMETER name
    Nombres de las frutas que se quieren consultar. Estan en ingles
.NOTES
    Se puden ingresar varias id y nombres, y la informacion que se consulte usara
    un cache para acceder a informacion buscada anteriormente mas rapido
.EXAMPLE
    ./ejercicio5.ps1 -id 1,2,3,4,5 -name Banana,Orange,Strawberry
.EXAMPLE
    ./ejercicio5.ps1 -id 1,2,3
.EXAMPLE
    ./ejercicio5.ps1 -name Banana,Orange
#>
[CmdletBinding(DefaultParameterSetName = 'id')]
param(
    [Parameter(Mandatory,ParameterSetName = 'id')]
    [Parameter(Mandatory,ParameterSetName = 'idName')]
    [ValidateRange("positive")]
    [int[]]$id,

    [Parameter(Mandatory,ParameterSetName = 'name')]
    [Parameter(Mandatory,ParameterSetName = 'idName')]
    [ValidateNotNullOrWhiteSpace()]
    [string[]]$name
    # [ValidatePattern("\<[A]")]
)

$id | ForEach-Object {Write-Host $_}
$name | ForEach-Object {Write-Host $_}