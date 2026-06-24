#!/bin/bash

# =====================================================
# Script de compilation automatique pour LaTeX
# Thèse Professionnelle - Drone Naval Autonome
# =====================================================

set -e  # Arrêter si une erreur se produit

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MAIN_FILE="these_corrigee_v2"
BIB_FILE="bibliography"

# Fonction pour afficher les messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Vérifier si les fichiers existent
check_files() {
    print_status "Vérification des fichiers..."
    
    if [ ! -f "${MAIN_FILE}.tex" ]; then
        print_error "Fichier ${MAIN_FILE}.tex non trouvé!"
        exit 1
    fi
    
    if [ ! -f "bibliography/${BIB_FILE}.bib" ]; then
        print_warning "Fichier bibliography/${BIB_FILE}.bib non trouvé!"
        print_status "Essai du chemin alternatif: ${BIB_FILE}.bib"
        if [ ! -f "${BIB_FILE}.bib" ]; then
            print_error "Fichier bibliographique non trouvé!"
            exit 1
        fi
    fi
    
    print_success "Fichiers trouvés"
}

# Nettoyer les fichiers temporaires
clean_temp() {
    print_status "Nettoyage des fichiers temporaires..."
    rm -f ${MAIN_FILE}.aux
    rm -f ${MAIN_FILE}.log
    rm -f ${MAIN_FILE}.out
    rm -f ${MAIN_FILE}.toc
    rm -f ${MAIN_FILE}.lof
    rm -f ${MAIN_FILE}.lot
    rm -f ${MAIN_FILE}.bbl
    rm -f ${MAIN_FILE}.blg
    rm -f ${MAIN_FILE}.fls
    rm -f ${MAIN_FILE}.fdb_latexmk
    print_success "Fichiers temporaires supprimés"
}

# Étape 1 : Compilation LaTeX initiale
compile_initial() {
    print_status "Étape 1/4 : Compilation LaTeX initiale..."
    
    if pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex > /dev/null 2>&1; then
        print_success "Compilation LaTeX réussie"
    else
        print_error "Erreur lors de la compilation LaTeX"
        pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex
        exit 1
    fi
}

# Étape 2 : Traitement bibliographique
compile_bib() {
    print_status "Étape 2/4 : Traitement de la bibliographie avec Biber..."
    
    if command -v biber &> /dev/null; then
        if biber ${MAIN_FILE} > /dev/null 2>&1; then
            print_success "Bibliographie traitée avec Biber"
        else
            print_error "Erreur lors du traitement Biber"
            biber ${MAIN_FILE}
            exit 1
        fi
    else
        print_warning "Biber non trouvé, essai avec BibTeX..."
        if bibtex ${MAIN_FILE} > /dev/null 2>&1; then
            print_success "Bibliographie traitée avec BibTeX"
        else
            print_error "Biber et BibTeX non trouvés ou erreur"
            exit 1
        fi
    fi
}

# Étape 3 : Recompilation avec bibliographie
compile_with_bib() {
    print_status "Étape 3/4 : Recompilation avec bibliographie..."
    
    if pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex > /dev/null 2>&1; then
        print_success "Recompilation réussie"
    else
        print_error "Erreur lors de la recompilation"
        pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex
        exit 1
    fi
}

# Étape 4 : Compilation finale
compile_final() {
    print_status "Étape 4/4 : Compilation finale pour références croisées..."
    
    if pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex > /dev/null 2>&1; then
        print_success "Compilation finale réussie"
    else
        print_error "Erreur lors de la compilation finale"
        pdflatex -interaction=nonstopmode -file-line-error ${MAIN_FILE}.tex
        exit 1
    fi
}

# Vérifier le résultat
check_result() {
    print_status "Vérification du résultat..."
    
    if [ -f "${MAIN_FILE}.pdf" ]; then
        FILE_SIZE=$(du -h "${MAIN_FILE}.pdf" | cut -f1)
        print_success "PDF généré avec succès! (${FILE_SIZE})"
        
        # Afficher des informations sur le PDF
        if command -v pdfinfo &> /dev/null; then
            NUM_PAGES=$(pdfinfo ${MAIN_FILE}.pdf | grep "Pages" | awk '{print $2}')
            print_status "Nombre de pages : ${NUM_PAGES}"
        fi
        
        return 0
    else
        print_error "PDF non généré!"
        return 1
    fi
}

# Fonction principale
main() {
    echo "========================================"
    echo "Compilation LaTeX - Thèse Professionnelle"
    echo "========================================"
    echo ""
    
    check_files
    
    # Option pour nettoyer avant compilation
    if [ "$1" == "--clean" ]; then
        clean_temp
    fi
    
    echo ""
    
    compile_initial
    compile_bib
    compile_with_bib
    compile_final
    
    echo ""
    
    if check_result; then
        echo ""
        print_success "Compilation terminée avec succès!"
        echo ""
        
        # Suggestions finales
        echo "Prochaines étapes :"
        echo "  - Vérifiez le PDF : ${MAIN_FILE}.pdf"
        echo "  - Table des matières : vérifiez les numéros de page"
        echo "  - Bibliographie : vérifiez les références"
        echo "  - Hyperliens : testez les liens dans le PDF"
        echo ""
        
        # Option pour ouvrir le PDF
        if [ "$2" == "--open" ]; then
            if command -v xdg-open &> /dev/null; then
                print_status "Ouverture du PDF..."
                xdg-open ${MAIN_FILE}.pdf
            elif command -v open &> /dev/null; then
                print_status "Ouverture du PDF..."
                open ${MAIN_FILE}.pdf
            fi
        fi
    else
        print_error "Compilation échouée. Vérifiez les messages d'erreur ci-dessus."
        exit 1
    fi
}

# Afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --clean     Nettoyer les fichiers temporaires avant compilation"
    echo "  --open      Ouvrir le PDF après compilation réussie (Linux/Mac)"
    echo "  --help      Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0                      # Compilation standard"
    echo "  $0 --clean              # Nettoyer puis compiler"
    echo "  $0 --clean --open       # Nettoyer, compiler et ouvrir"
}

# Traiter les arguments
case "$1" in
    --help|-h)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
