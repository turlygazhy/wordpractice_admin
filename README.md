# Обновление GitHub Pages для Flutter Web

Эта инструкция описывает, как обновлять сайт Flutter Web, размещённый на GitHub Pages.

---

## Шаг 1. Сборка Flutter Web

В корне проекта выполните команду:

```bash
flutter build web --base-href /wordpractice_admin/

Шаг 2. Копирование билда в папку docs

GitHub Pages настроен на ветку main → папка /docs.

rm -rf docs/*
cp -r build/web/* docs/


Все файлы из build/web должны оказаться сразу в docs/

Не оставляйте вложенную папку web внутри docs, иначе GitHub Pages не найдёт index.html