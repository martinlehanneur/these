# =====================================================
# Script de compilation automatique pour LaTeX - Windows
# Thèse Professionnelle - Drone Naval Autonome
# =====================================================

param(
    [switch]$Clean = $false,
    [switch]$Open = $false,
    [switch]$Help = $false
)

# Configuration
$MAIN_FILE = "these_corrigee_v2"
$BIB_FILE = "bibliography"

# Fonctions pour l'affichage
function Print-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Print-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERREUR] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[ATTENTION] $Message" -ForegroundColor Yellow
}

function Show-Help {
    Write-Host "Usage: .\compile.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Clean     Nettoyer les fichiers temporaires avant compilation"
    Write-Host "  -Open      Ouvrir le PDF après compilation réussie"
    Write-Host "  -Help      Afficher cette aide"
    Write-Host ""
    Write-Host "Exemples:"
    Write-Host "  .\compile.ps1                    # Compilation standard"
    Write-Host "  .\compile.ps1 -Clean             # Nettoyer puis compiler"
    Write-Host "  .\compile.ps1 -Clean -Open       # Nettoyer, compiler et ouvrir"
}

# Vérifier les fichiers
function Check-Files {
    Print-Status "Vérification des fichiers..."
    
    if (-not (Test-Path "$MAIN_FILE.tex")) {
        Print-Error "Fichier $MAIN_FILE.tex non trouvé!"
        exit 1
    }
    
    if (-not (Test-Path "bibliography/$BIB_FILE.bib")) {
        Print-Warning "Fichier bibliography/$BIB_FILE.bib non trouvé!"
        Print-Status "Essai du chemin alternatif: $BIB_FILE.bib"
        if (-not (Test-Path "$BIB_FILE.bib")) {
            Print-Error "Fichier bibliographique non trouvé!"
            exit 1
        }
    }
    
    Print-Success "Fichiers trouvés"
}

# Nettoyer les fichiers temporaires
function Clean-TempFiles {
    Print-Status "Nettoyage des fichiers temporaires..."
    
    $tempFiles = @(
        "$MAIN_FILE.aux",
        "$MAIN_FILE.log",
        "$MAIN_FILE.out",
        "$MAIN_FILE.toc",
        "$MAIN_FILE.lof",
        "$MAIN_FILE.lot",
        "$MAIN_FILE.bbl",
        "$MAIN_FILE.blg",
        "$MAIN_FILE.fls",
        "$MAIN_FILE.fdb_latexmk"
    )
    
    foreach ($file in $tempFiles) {
        if (Test-Path $file) {
            Remove-Item $file -Force
        }
    }
    
    Print-Success "Fichiers temporaires supprimés"
}

# Vérifier si pdflatex est disponible
function Check-PDFLaTeX {
    try {
        $null = pdflatex -version 2>&1
        return $true
    } catch {
        return $false
    }
}

# Vérifier si biber est disponible
function Check-Biber {
    try {
        $null = biber --version 2>&1
        return $true
    } catch {
        return $false
    }
}

# Étape 1 : Compilation LaTeX initiale
function Compile-Initial {
    Print-Status "Étape 1/4 : Compilation LaTeX initiale..."
    
    $output = pdflatex -interaction=nonstopmode -file-line-error $MAIN_FILE.tex 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Compilation LaTeX réussie"
    } else {
        Print-Error "Erreur lors de la compilation LaTeX"
        Write-Host $output
        exit 1
    }
}

# Étape 2 : Traitement bibliographique
function Compile-Bib {
    Print-Status "Étape 2/4 : Traitement de la bibliographie..."
    
    if (Check-Biber) {
        $output = biber $MAIN_FILE 2>&1
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Bibliographie traitée avec Biber"
        } else {
            Print-Error "Erreur lors du traitement Biber"
            Write-Host $output
            exit 1
        }
    } else {
        Print-Warning "Biber non trouvé, essai avec BibTeX..."
        $output = bibtex $MAIN_FILE 2>&1
        if ($LASTEXITCODE -eq 0) {
            Print-Success "Bibliographie traitée avec BibTeX"
        } else {
            Print-Error "BibTeX erreur ou non trouvé"
            Write-Host $output
            exit 1
        }
    }
}

# Étape 3 : Recompilation avec bibliographie
function Compile-WithBib {
    Print-Status "Étape 3/4 : Recompilation avec bibliographie..."
    
    $output = pdflatex -interaction=nonstopmode -file-line-error $MAIN_FILE.tex 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Recompilation réussie"
    } else {
        Print-Error "Erreur lors de la recompilation"
        Write-Host $output
        exit 1
    }
}

# Étape 4 : Compilation finale
function Compile-Final {
    Print-Status "Étape 4/4 : Compilation finale pour références croisées..."
    
    $output = pdflatex -interaction=nonstopmode -file-line-error $MAIN_FILE.tex 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Compilation finale réussie"
    } else {
        Print-Error "Erreur lors de la compilation finale"
        Write-Host $output
        exit 1
    }
}

# Vérifier le résultat
function Check-Result {
    Print-Status "Vérification du résultat..."
    
    if (Test-Path "$MAIN_FILE.pdf") {
        $file = Get-Item "$MAIN_FILE.pdf"
        $fileSize = "{0:N2} MB" -f ($file.Length / 1MB)
        Print-Success "PDF généré avec succès! ($fileSize)"
        return $true
    } else {
        Print-Error "PDF non généré!"
        return $false
    }
}

# Ouvrir le PDF
function Open-PDF {
    if (Test-Path "$MAIN_FILE.pdf") {
        Print-Status "Ouverture du PDF..."
        & "$MAIN_FILE.pdf"
    }
}

# Fonction principale
function Main {
    Write-Host "========================================"
    Write-Host "Compilation LaTeX - Thèse Professionnelle"
    Write-Host "========================================"
    Write-Host ""
    
    # Vérifier pdflatex
    if (-not (Check-PDFLaTeX)) {
        Print-Error "pdflatex n'est pas disponible!"
        Print-Error "Veuillez installer TeX Live ou MiKTeX"
        exit 1
    }
    
    Check-Files
    
    if ($Clean) {
        Clean-TempFiles
    }
    
    Write-Host ""
    
    Compile-Initial
    Compile-Bib
    Compile-WithBib
    Compile-Final
    
    Write-Host ""
    
    if (Check-Result) {
        Write-Host ""
        Print-Success "Compilation terminée avec succès!"
        Write-Host ""
        Write-Host "Prochaines étapes :"
        Write-Host "  - Vérifiez le PDF : $MAIN_FILE.pdf"
        Write-Host "  - Table des matières : vérifiez les numéros de page"
        Write-Host "  - Bibliographie : vérifiez les références"
        Write-Host "  - Hyperliens : testez les liens dans le PDF"
        Write-Host ""
        
        if ($Open) {
            Open-PDF
        }
    } else {
        Print-Error "Compilation échouée. Vérifiez les messages d'erreur ci-dessus."
        exit 1
    }
}

# Exécuter
if ($Help) {
    Show-Help
} else {
    Main
}
