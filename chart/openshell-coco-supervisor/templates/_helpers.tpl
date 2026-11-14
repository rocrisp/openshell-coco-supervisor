{{/*
Common labels for resources owned by this chart.
*/}}
{{- define "openshell-coco.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: openshell-coco-supervisor
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Return the Helm release that owns an object, if any.
*/}}
{{- define "openshell-coco.owner" -}}
{{- $obj := . -}}
{{- $owner := "" -}}
{{- if $obj -}}
  {{- if $obj.metadata -}}
    {{- if $obj.metadata.annotations -}}
      {{- $owner = index $obj.metadata.annotations "meta.helm.sh/release-name" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $owner -}}
{{- end }}

{{/*
Render a named resource if it is missing or already owned by this release.
Skip it when it exists but is owned by another manager.
*/}}
{{- define "openshell-coco.shouldRenderNamed" -}}
{{- $obj := .object -}}
{{- $release := .release -}}
{{- $owner := include "openshell-coco.owner" $obj -}}
{{- if or (not $obj) (eq $owner $release) -}}true{{- else -}}false{{- end -}}
{{- end }}

{{/*
Render a Subscription if no Subscription for the package exists, or if the
matching Subscription is owned by this release. This avoids creating a second
subscription when an operator was already installed under another name.
*/}}
{{- define "openshell-coco.subscriptionShouldRender" -}}
{{- $list := .list -}}
{{- $package := .package -}}
{{- $release := .release -}}
{{- $name := .name -}}
{{- $found := false -}}
{{- $ours := false -}}
{{- range $key, $sub := $list -}}
  {{- if $sub.spec.name -}}
    {{- if eq $sub.spec.name $package -}}
      {{- $found = true -}}
      {{- $owner := include "openshell-coco.owner" $sub -}}
      {{- if and (eq $sub.metadata.name $name) (eq $owner $release) -}}
        {{- $ours = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if or (not $found) $ours -}}true{{- else -}}false{{- end -}}
{{- end }}

{{/*
Render a singleton custom resource if none exists, or if the resource with this
chart's name is already owned by this release.
*/}}
{{- define "openshell-coco.listShouldRender" -}}
{{- $list := .list -}}
{{- $release := .release -}}
{{- $name := .name -}}
{{- $found := false -}}
{{- $ours := false -}}
{{- range $key, $item := $list -}}
  {{- $found = true -}}
  {{- $owner := include "openshell-coco.owner" $item -}}
  {{- if and (eq $item.metadata.name $name) (eq $owner $release) -}}
    {{- $ours = true -}}
  {{- end -}}
{{- end -}}
{{- if or (not $found) $ours -}}true{{- else -}}false{{- end -}}
{{- end }}
