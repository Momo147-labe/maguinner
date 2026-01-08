# Configuration Windows Defender pour Gestion Moderne de Magasin
# A executer en tant qu'administrateur (optionnel)

Write-Host "Configuration Windows Defender..." -ForegroundColor Green

# Ajouter exclusion pour le dossier d'installation
$installPath = "$env:ProgramFiles\Gestion moderne de magasin"
$appDataPath = "$env:LOCALAPPDATA\com.fodemomo.gestion_moderne_magasin"

try {
    # Exclusions Defender
    Add-MpPreference -ExclusionPath $installPath -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath $appDataPath -ErrorAction SilentlyContinue
    
    # Exclusion processus
    Add-MpPreference -ExclusionProcess "gestion_moderne_magasin.exe" -ErrorAction SilentlyContinue
    
    Write-Host "Exclusions Windows Defender ajoutees avec succes!" -ForegroundColor Green
    
} catch {
    Write-Host "Erreur lors de la configuration Defender: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Ceci est optionnel - l'application fonctionnera quand meme." -ForegroundColor Yellow
}

# Regles Firewall (deja gerees par l'installer)
Write-Host "Les regles Firewall sont gerees automatiquement par l'installer." -ForegroundColor Blue

Write-Host "Configuration terminee!" -ForegroundColor Green
Read-Host "Appuyez sur Entree pour continuer..."