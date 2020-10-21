import-module activedirectory

while ($true) {

$nameds = read-host "Welcher User soll kopiert werden?" #fragt den Admin nach dem Anmeldenamen des zu kopierenden Users und speichert diesen in einer Variable.

if($nameds -eq "")
{
 write-host "Der Username darf nicht leer sein. Bitte versuchen Sie es erneut."
}
elseif (dsquery user -samid $nameds)
{
 write-host "User gefunden"
 break
}
else 
{
 write-host "User nicht gefunden"
}

}  <# in der AD wird nach einem User mit dem gleichen namen wie eben angegeben gesucht, wenn dieser gefunden wird gibt das Skript aus, dass der User gefunden wurde. 
      Wenn kein passender User gefunden wurde wird eine Fehlermeldung ausgegeben. #>



$newuser = read-host "Anmeldename des neuen Users"         #fragt nach dem Anmeldenamen für den neuen User und speichert ihn in Variable.

if(!(dsquery user -samid $newuser)){ #Checkt ob bereits ein User mit diesem Anmeldenamen existiert.

$name = get-aduser -identity $nameds -properties *         #speichert den ADUser der kopiert werden soll und alle seine Eigenschaften ab.
$dn = $name.distinguishedName                              #in dieser Variable steckt der distinguished name (DN) des zu kopierenden Users.
$olduser = [ADSI]"LDAP://$DN"                              #setzt in Kombination mit dem DN den Pfad des Users in der AD zusammen.
$parent = $olduser.parent                                  #greift den pfad der übergeordneten OU des zu kopierneden User ab.
$ou = [ADSI]$parent                                        #greift die tatsächliche parent OU des Users ab.
$oudn = $ou.distinguishedName                              #greift den distinguished name der parent OU ab.
$firstname = read-host "Vorname"                           #speichert Vornamen.
$lastname = read-host "Nachname"                           #speichert Nachnamen.
$newname = "$firstname $lastname"
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()      #greift aktuelle Domäne ab.
                  
if($name.ProfilePath) {                                                  #Fail-Safe für den fall, dass der Profilpfad des kopierten ADUser nicht gesetzt wurde.
$profpath = $name.ProfilePath.Replace($nameds, $newuser)                 #greift den Profilpfad des kopierten ADUsers ab, passt diesen für den neuen ADUser an und speichert ihn in einer Variable.  
}

if($name.HomeDirectory) {                                                #Fail-Safe für den fall, dass der Basisordnerpfad des kopierten ADUser nicht gesetzt wurde.
$basedrive = $name.HomeDrive                                             #greift den Laufwerksbuchsstaben für den Basisordner des kopierten ADUsers ab und speichert ihn in einer Variable.  
$basepath = $name.HomeDirectory.Replace($nameds, $newuser)               #greift den Basisordnerpfad des kopierten ADUsers ab, passt diesen für den neuen ADUser an und speichert ihn in einer Variable.
}

#erstellt den neuen ADUser in der Active Directory
new-aduser -samaccountname $newuser -name $newname -givenname $firstname -displayname "$firstname $lastname" -surname $lastname -instance $dn -path "$oudn" -accountpassword (read-host "new password" -assecurestring) -userprincipalname $newuser@$domain
set-aduser -identity $newuser -changepasswordatlogon $true #aktiviert die Kontooption "Benutzer muss Kennwort bei der nächsten Anmeldung ändern" für den neuen ADUser.
set-aduser -identity $newuser -ProfilePath $profpath       #setzt den Profilpfad für den neuen ADUser fest.
set-aduser -identity $newuser -HomeDrive $basedrive        #setzt den Laufwerksbuchstaben für den Basisordner des neuen ADUser fest.
set-aduser -identity $newuser -HomeDirectory $basepath     #setzt den Basisordnerpfad für den neuen ADUser fest.
set-aduser -Identity $newuser -Enabled $true               #deaktiviert die Kontooption "Konto ist deaktiviert" für den neuen ADUser.
#erstellt den neuen User und setzt verschiedene Eigenschaften, erstellt das Homelaufwerk 
                                                           
$groups = (get-aduser -identity $name -properties memberof).MemberOf     #Variable die den zu kopierenden User und seine Gruppen abgreift
foreach ($group in $groups) {
add-adgroupmember -identity $group -members $newuser
}  #fügt den neuen user einmal jeder gruppe hinzu in der der Base-User Mitglied ist

$count = $groups.count

}
else
{
write-host "User existiert bereits."
PAUSE  #wartet auf einen input des Anwenders.
return #beendet das Script an dieser Stelle.
}
                                                           
if(dsquery user -samid $newuser)                           #checkt ob der user nun in der Active Directory vorhanden ist und wirft eine Meldung aus.
{
write-host "User erfolgreich erstellt."
}
else
{
write-host "User Erstellung fehlgeschlagen."
}
PAUSE #wartet auf einen input des Anwenders.
