# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra) 
"SHOPPERIA" är en blocket-liknande webshop som man kan lägga upp varor så att andra kan se den. Man ska kunna göra ett konto, logga in och sedan göra en "listing". Sedan ska man även kunna visa sin egen profil och vilka varor man själv lagt upp och man ska kunna ändra sin profilbild. Sedan ska man även kunna uppdatera sin vara om man vill och om man äger varan eller är admin ska man kunna ta bort den. Man ska även kunna ta bort andra användare om man är admin.
## 2. Vyer (visa bildskisser på dina sidor)
Har inga skisser kvar tyvärr, hade det mesta i huvudet redan så jag visste ungefär hur jag ville göra.
## 3. Databas med ER-diagram (Bild)

![ER-diagram](ER-diagram.png)

## 4. Arkitektur (Beskriv filer och mappar - vad gör/inehåller de?)
│   .byebug_history\
│   app.rb\
* innehåller alla routes \
│   gemfile\
│   gemfile.lock\
│   model.rb\
* innehåller all databaskod \
│\
├───.yardoc\
│\
├───db\
* innehåller databasen \
│       database.db\
│       database.db.sqbpro\
│\
├───doc\
* innehåller all docs \
├───public\
│   ├───css\
* innehåller css \
│   │\
│   ├───img\
* innehåller alla bilder \
│   └───js\
└───views\
    │   error.slim\
    │   index.slim\
    │   layout.slim\
    │\
    ├───users\
    * innehåller alla slim filer som har något med users att göra \
    │       adminsettings.slim\
    │       login.slim\
    │       profile.slim\
    │       register.slim\
    │\
    └───webshop\
    * innehåller alla slim filer som har något med själva webshopen att göra \
            createlisting.slim\
            update.slim\
            upload.slim\
            webshop.slim\
