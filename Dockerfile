FROM grafana/grafana-oss:11.2.1

##################################################################
## CONFIGURATION
##################################################################

## Set Grafana options
ENV GF_ENABLE_GZIP=true
ENV GF_USERS_DEFAULT_THEME=light

## Enable Anonymous Authentication
ENV GF_AUTH_ANONYMOUS_ENABLED=true
ENV GF_AUTH_BASIC_ENABLED=false

## Disable Sanitize
ENV GF_PANELS_DISABLE_SANITIZE_HTML=true
ENV GF_SECURITY_ALLOW_EMBEDDING=true

## Check for Updates
ENV GF_ANALYTICS_CHECK_FOR_UPDATES=false

## Scenes-engine Dashboards
# ENV GF_FEATURE_TOGGLES_ENABLE=dashboardScene

## Set Home Dashboard
ENV GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/etc/grafana/provisioning/dashboards/business.json

## Paths
ENV GF_PATHS_PROVISIONING="/etc/grafana/provisioning"
ENV GF_PATHS_PLUGINS="/var/lib/grafana/plugins"

##################################################################
## Copy Artifacts
## Required for the App plugin
##################################################################

#COPY --chown=grafana:root dist /app
COPY entrypoint.sh /

## Copy Provisioning
COPY --chown=grafana:root provisioning $GF_PATHS_PROVISIONING

##################################################################
## Customization depends on the Grafana version
## May work or not work for the version different from the current
## Check GitHub file history for the previous Grafana versions
##################################################################
USER root

##################################################################
## VISUAL
## Update Image files
##################################################################

## Replace Favicon and Apple Touch
COPY img/fav32.png /usr/share/grafana/public/img
COPY img/fav32.png /usr/share/grafana/public/img/apple-touch-icon.png

## Replace Logo
COPY img/logo.svg /usr/share/grafana/public/img/grafana_icon.svg

## Update Background
COPY img/background.svg /usr/share/grafana/public/img/g8_login_dark.svg
COPY img/background.svg /usr/share/grafana/public/img/g8_login_light.svg

##################################################################
## HANDS-ON
## Update HTML, INI files
##################################################################

# Update Title
RUN sed -i 's|<title>\[\[.AppTitle\]\]</title>|<title>MIOBOX App</title>|g' /usr/share/grafana/public/views/index.html
RUN sed -i 's|Loading Grafana|Loading MIOBOX App|g' /usr/share/grafana/public/views/index.html

## Update Mega and Help menu
RUN sed -i "s|\[\[.NavTree\]\],|nav,|g; \
    s|window.grafanaBootData = {| \
    let nav = [[.NavTree]]; \
    const alerting = nav.find((element) => element.id === 'alerting'); \
    if (alerting) { alerting['url'] = '/alerting/list'; } \
    const dashboards = nav.find((element) => element.id === 'dashboards/browse'); \
    if (dashboards) { dashboards['children'] = [];} \
    const connections = nav.find((element) => element.id === 'connections'); \
    if (connections) { connections['url'] = '/datasources'; connections['children'].shift(); } \
    const help = nav.find((element) => element.id === 'help'); \
    if (help) { help['subTitle'] = 'Business App 4.3.0'; help['children'] = [];} \
    window.grafanaBootData = {|g" \
    /usr/share/grafana/public/views/index.html

# Move Business App to navigation root section
RUN sed -i 's|\[navigation.app_sections\]|\[navigation.app_sections\]\nbusiness-app=root|g' /usr/share/grafana/conf/defaults.ini

##################################################################
## HANDS-ON
## Update JavaScript files
##################################################################

RUN find /usr/share/grafana/public/build/ -name *.js \
    ## Update Title
    -exec sed -i 's|AppTitle="Grafana"|AppTitle="MIOBOX DASH"|g' {} \; \
    ## Update Login Title
    -exec sed -i 's|LoginTitle="Welcome to Grafana"|LoginTitle="MIOBOX Dashboard"|g' {} \; \
    ## Remove Documentation, Support, Community in the Footer
    -exec sed -i 's|\[{target:"_blank",id:"documentation".*grafana_footer"}\]|\[\]|g' {} \; \
    ## Remove Edition in the Footer
    -exec sed -i 's|({target:"_blank",id:"license",.*licenseUrl})|()|g' {} \; \
    ## Remove Version in the Footer
    -exec sed -i 's|({target:"_blank",id:"version",.*CHANGELOG.md":void 0})|()|g' {} \; \
    ## Remove News icon
    -exec sed -i 's|(.,.....)(....,{className:.,onClick:.,iconOnly:!0,icon:"rss","aria-label":"News"})|null|g' {} \; \
    ## Remove Open Source icon
    -exec sed -i 's|.push({target:"_blank",id:"version",text:`${..edition}${.}`,url:..licenseUrl,icon:"external-link-alt"})||g' {} \;

##################################################################
## CLEANING
## Remove Native Data Sources
##################################################################


## Remove Cloud and Enterprise categories
RUN find /usr/share/grafana/public/build/ -name *.js \
    -exec sed -i 's|.id==="enterprise"|.id==="notanenterprise"|g' {} \; \
    -exec sed -i 's|.id==="cloud"|.id==="notacloud"|g' {} \;

##################################################################
## CLEANING
## Remove Native Panels
##################################################################



##################################################################

USER grafana

## Entrypoint
ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]