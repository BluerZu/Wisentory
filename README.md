# Wisentory
Pasos para instalarlo:
1. Cargar el archivo "WisentoryDB.bak" en la base de datos sql server
2. Abrir en Visual Studio el proyecto "Wisentory" dentro del zip y en el archivo app.config
3. Cambiar la línea de la conexión con la base de datos, el "Data Source" del connectionString a la de la base de datos
Ejemplo:
 <add name="WisentoryDB" connectionString="Data Source=<Aqui va el servidor de la base de datos>;Initial Catalog=WisentoryDB;User ID=WisentoryManager;Password=admin"/>
 <add name="WisentoryDB" connectionString="Data Source=PC-LUIS\SQLEXPRESS;Initial Catalog=WisentoryDB;User ID=WisentoryManager;Password=admin"/>

