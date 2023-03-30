#!/bin/bash
# Modify favicon
sed -i 's/\[\[.AppTitle\]\]/dNation/g' /usr/share/grafana/public/views/index.html
sed -i 's/\[\[.AppTitle\]\]/dNation/g' /usr/share/grafana/public/views/index-template.html
sed -i 's/\[\[.FavIcon\]\]/https:\/\/storage.googleapis.com\/cdn.ifne.eu\/public\/icons\/dnation_k8sm8g.png/g' /usr/share/grafana/public/views/index.html
#Modify logp
sed -i 's@public/img/grafana_icon.svg@public/img/dnation_logo.svg@g' /usr/share/grafana/public/build/*.*
#Modify app title
sed -i 's/"AppTitle","Grafana"/"AppTitle","dNation"/g' /usr/share/grafana/public/build/*.*
sed -i "s/static AppTitle = 'Grafana'/static AppTitle = 'dNation'/g" /usr/share/grafana/public/build/*.*
#Modify welcome message
sed -i 's/Welcome to Grafana/dNation Kubernetes Monitoring/g' /usr/share/grafana/public/build/*.*
#Modify the docs
sed -i 's@https://grafana.com/docs/grafana/latest/?utm_source=grafana_footer@https://github.com/dNationCloud/kubernetes-monitoring@g' /usr/share/grafana/public/build/*.*