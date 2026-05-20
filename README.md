# planner

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## GitHub Pages

При каждом push в `master` или `main` workflow [deploy-gh-pages.yml](.github/workflows/deploy-gh-pages.yml) собирает Flutter Web и публикует артефакты в ветку `gh-pages`.

**Важно:** в **Settings → Pages → Build and deployment** источник должен быть **Deploy from a branch**, ветка **`gh-pages`**, папка **`/ (root)`**.

Не выбирайте `main` или `master` — там только исходники, без сборки Flutter. Если в интерфейсе написано «ветка main», это часто означает старую настройку на основную ветку; переключите явно на `gh-pages`.

Сайт: https://wookeybiscotti.github.io/TeamPlanner/
