#!/bin/bash

# Recebe o nome do subdomínio como argumento
read -p "Digite o nome do subdomínio: " subdomain

read -p "Digite a porta do subdomínio: " port

read -p "Informe o nome da base URL que será utilizado para o mapeamento do proxy reverso: " baseURL

# Cria o caminho completo para o arquivo de configuração
conf_file="/etc/nginx/sites-enabled/$subdomain.conf"

# Copia o arquivo template.conf para o novo arquivo de configuração
cp /etc/nginx/sites-available/template.conf /etc/nginx/sites-available/$subdomain.conf

# Criar link para site-enabled  
sudo ln -s /etc/nginx/sites-available/$subdomain.conf /etc/nginx/sites-enabled/$subdomain.conf

# Define o valor que será usado na substituição
var="DOMAIN"
val=$subdomain

varPort="PORT"
valPort=$port

varBaseURL="BASEURL"
valBaseURL=$baseURL

# Substiutui todas as ocorrências da variável pelo valor no arquivo de configuração
sed -i "s/$var/$val/g" "$conf_file"
sed -i "s/$varPort/$valPort/g" "$conf_file"
sed -i "s/$varBaseURL/$valBaseURL/g" "$conf_file"

aws ssm send-command --document-name "AWS-RunShellScript" --document-version "1" --targets '[{"Key":"tag:nginx", "Values":["reload"]}]' --parameters '{"workingDirectory":[""],"executionTimeout":["3600"],"commands":["sudo service nginx reload"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region "us-west-2"
sleep 10

sudo certbot --nginx -d $subdomain
aws ssm send-command --document-name "AWS-RunShellScript" --document-version "1" --targets '[{"Key":"tag:nginx", "Values":["reload"]}]' --parameters '{"workingDirectory":[""],"executionTimeout":["3600"],"commands":["sudo service nginx reload"]}' --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region "us-west-2"