# ![logo](/dotnetwrapper_v3.png) PowerShell_Dot_Net_Wrapper
_A PowerShell module that wraps .net classes into functions_

##Module Background

Many of my colleagues are surprised that you can actually access `.NET` objects with powershell.  Over the years I've preferred to use `.NET` classes and objects quite often over `cmdlets` or `functions` provided by PowerShell or by some third party.

The aim of this repository is to maintain a module that contains a number of functions that take advantage of `.NET`; and to share that with others as sort of a reference.

Additionally, recently in my company we have begun to move toward **infrastructure as code**.  My company is also interested in creating a shared code repository.  Typically for many years now all my code was used by me or was used by others but maintained by me.  I've written many automatons and scripts over the years but never really practiced any type of [PowerShell best practices or styles](https://github.com/PoshCode/PowerShellPracticeAndStyle).  

So, in addition to providing a reference for using `.NET` with PowerShell, I've also taken advantage of this project to force myself into new workflows that will make it easier to follow best practices.  For example:

- I've changed my editor to [VSCode](https://github.com/Microsoft/vscode); a very popular editor which has a very good PowerShell extension.
- I've changed the way I develop modules (e.g. moving functions to individual files) - if you looked at this modules two weeks ago all the functionality was in one file.
  - Because I've changed the way I've developed modules, it is now easier to test my functions.  This repository now includes a number of code validity tests using Pester.
- Because I'm testing my modules this repository is can also be used as a reference on writing Pester tests.  There are more tests to come...

##Technical Reference

This module is about showing how to use `.NET` with PowerShell.  Here is a list of the functions in this module and the `.NET` classes they utilize.  As a note "Helper" functions are not meant as examples of using `.NET`, but are there to help the other functions.
- DS-Functions_
  - **Get-DSObjects** using:
    - `System.DirectoryServices.DirectoryEntry`
    - `System.DirectoryServices.DirectorySearcher`
  - **Get-Domain** using:
    - `System.DirectoryServices.ActiveDirectory.Domain`
    - `System.DirectoryServices.ActiveDirectory.DirectoryContext`
  - **Get-DomainController** using:
    - `System.DirectoryServices.ActiveDirectory.DirectoryContext`
    - `System.DirectoryServices.ActiveDirectory.Domain`
  - **Get-ForestTrustInfo** using:
    - `System.DirectoryServices.ActiveDirectory.DirectoryContext`
    - `System.DirectoryServices.ActiveDirectory.DirectoryContext`
    - `System.DirectoryServices.ActiveDirectory.Forest`
  - **Set-DSObject** using:
    - `System.DirectoryServices.DirectoryEntry`
- Net-Functions
  - **Ping-Host** using:
    - `System.Net.NetworkInformation.Ping`
- CodeAnalysis-Functions
  - **Find-ScriptCommand** using:
    - `System.Management.Automation.PSParser`
    - `System.Collections.Generic.List`



