#!/bin/bash

# Modify favicon
sed -i 's/\[\[.AppTitle\]\]/dNation/g' /usr/share/grafana/public/views/index.html
sed -i 's/\[\[.FavIcon\]\]/https:\/\/storage.googleapis.com\/ifne.eu\/public\/icons\/dnation_k8sm8g.png/g' /usr/share/grafana/public/views/index.html
# Modify login screen and home button
sed -i 's/className:t,src:"public\/img\/grafana_icon.svg",alt:"Grafana"/className:t,src:"public\/img\/dnation_logo.svg",alt:"dNation"/g' /usr/share/grafana/public/build/app.*
sed -i 's/AppTitle="Grafana",u.LoginTitle="Welcome to Grafana"/AppTitle="dNation",u.LoginTitle="dNation Kubernetes Monitoring"/g' /usr/share/grafana/public/build/app.*
sed -i 's/e=\["Don\x27t get in the way of the data","Your single pane of glass","Built better together","Democratising data"\]/e=\[\]/g' /usr/share/grafana/public/build/app.*
# Modify home screen
sed -i 's/"Welcome to Grafana"/"Welcome to dNation Kubernetes Monitoring"/g' /usr/share/grafana/public/build/app.*
sed -i 's/Mc=\[{value:0,label:"Documentation",href:"https:\/\/grafana.com\/docs\/grafana\/latest"},{value:1,label:"Tutorials",href:"https:\/\/grafana.com\/tutorials"},{value:2,label:"Community",href:"https:\/\/community.grafana.com"},{value:3,label:"Public Slack",href:"http:\/\/slack.grafana.com"}\]/Mc=\[{value:0,label:"Documentation",href:"https:\/\/github.com\/dNationCloud\/kubernetes-monitoring"}\]/g' /usr/share/grafana/public/build/app.*
