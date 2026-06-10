# Planner

Веб-приложение на React Flow для визуализации задач из TFS / Azure DevOps в виде графа связей.

## Возможности

- Загрузка задач по `System.AreaPath` (с вложенными путями или точным совпадением)
- Загрузка одной задачи по ID
- Граф: родитель → ребёнок, блокер → задача
- Настраиваемая схема полей, отображаемых в ноде
- При первом запуске запрашиваются Base URL и Personal Access Token (хранятся в `localStorage`)

## Локальная разработка

```bash
npm install
npm run dev
```

## Сборка

```bash
npm run build
```

Артефакты — в папке `dist/`.

## GitHub Pages

При push в `master` или `main` workflow [deploy-gh-pages.yml](.github/workflows/deploy-gh-pages.yml) собирает статический сайт и публикует его в ветку `gh-pages`.

В **Settings → Pages → Build and deployment** укажите источник **Deploy from a branch**, ветка **`gh-pages`**, папка **`/ (root)`**.

Сайт: https://wookeybiscotti.github.io/TeamPlanner/

## API

Base URL — корень проекта в Azure DevOps, например:

- `https://dev.azure.com/{organization}/{project}`
- `https://tfs.example.com/tfs/{collection}/{project}`

PAT должен иметь права **Work Items (Read)**.

### Ограничения веб-приложения

- **CORS**: прямые запросы к on-prem TFS из браузера требуют настройки CORS на сервере; Azure DevOps (`dev.azure.com`) обычно работает из коробки.
- **Секреты**: PAT хранится только в `localStorage` браузера и не попадает в сборку или CI.
- **NTLM**: в веб-приложении не поддерживается — только PAT. Для NTLM используйте CLI-утилиту ниже.

## CLI-утилита (отладка API)

Скрипт [`scripts/get_work_item.py`](scripts/get_work_item.py) — референсная реализация загрузки задач (WIQL, batch fetch). Не участвует в CI.

```bash
cd scripts
cp .env.example .env
# заполните TFS_URL и TFS_PAT (или TFS_USERNAME + TFS_PASSWORD для NTLM)
pip install -r requirements.txt

python get_work_item.py get 12345
python get_work_item.py by-area "IResearch\KSN-AMR" --exclude-state Closed --exclude-state Removed
python get_work_item.py by-area "IResearch\KSN-AMR" -o tasks.json
```
