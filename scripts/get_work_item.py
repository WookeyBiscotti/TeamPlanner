#!/usr/bin/env python3
"""Получение work items из TFS / Azure DevOps Server."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

import requests
from dotenv import load_dotenv

try:
    from requests_ntlm import HttpNtlmAuth
except ImportError:
    HttpNtlmAuth = None  # type: ignore[misc, assignment]

BATCH_SIZE = 200


def load_config(env_path: Path | None = None) -> None:
    """Загружает переменные из .env в корне проекта."""
    root = Path(__file__).resolve().parent
    path = env_path or root / ".env"
    if not path.is_file():
        raise FileNotFoundError(
            f"Файл {path} не найден. Скопируйте .env.example в .env и заполните значения."
        )
    load_dotenv(path)


def get_base_url() -> str:
    base_url = os.getenv("TFS_URL", "").strip().rstrip("/")
    if not base_url:
        raise ValueError("В .env не задан TFS_URL")
    return base_url


def get_api_version() -> str:
    return os.getenv("TFS_API_VERSION", "6.0").strip()


def build_auth() -> tuple[dict[str, str] | None, Any]:
    pat = os.getenv("TFS_PAT", "").strip()
    if pat:
        return None, ("", pat)

    username = os.getenv("TFS_USERNAME", "").strip()
    password = os.getenv("TFS_PASSWORD", "")
    if username and password:
        if HttpNtlmAuth is None:
            raise RuntimeError(
                "Для NTLM установите зависимости: pip install requests-ntlm"
            )
        return None, HttpNtlmAuth(username, password)

    raise ValueError(
        "В .env укажите TFS_PAT или пару TFS_USERNAME + TFS_PASSWORD"
    )


def get_ssl_verify() -> bool | str:
    ca_bundle = os.getenv("TFS_CA_BUNDLE", "").strip()
    if ca_bundle:
        path = Path(ca_bundle)
        if not path.is_file():
            raise FileNotFoundError(f"TFS_CA_BUNDLE: файл не найден: {path}")
        return str(path)

    verify_ssl = os.getenv("TFS_VERIFY_SSL", "true").lower() not in (
        "0",
        "false",
        "no",
    )
    if not verify_ssl:
        import urllib3

        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    return verify_ssl


def tfs_request(
    method: str,
    path: str,
    *,
    params: dict[str, str] | None = None,
    json_body: dict[str, Any] | None = None,
) -> requests.Response:
    url = f"{get_base_url()}/{path.lstrip('/')}"
    headers, auth = build_auth()
    request_headers = {"Content-Type": "application/json"} if json_body else headers

    response = requests.request(
        method,
        url,
        params=params,
        json=json_body,
        headers=request_headers,
        auth=auth,
        timeout=int(os.getenv("TFS_TIMEOUT", "60")),
        verify=get_ssl_verify(),
    )

    if not response.ok:
        raise requests.HTTPError(
            f"{response.status_code} {response.reason}: {response.text}",
            response=response,
        )

    return response


def escape_wiql(value: str) -> str:
    return value.replace("'", "''")


def normalize_exclude_states(values: list[str] | None) -> list[str]:
    """Разбирает --exclude-state Closed,Removed и повторяющиеся флаги."""
    result: list[str] = []
    for value in values or []:
        for part in value.split(","):
            state = part.strip()
            if state and state not in result:
                result.append(state)
    return result


def build_state_exclusion_clause(exclude_states: list[str]) -> str:
    if not exclude_states:
        return ""
    if len(exclude_states) == 1:
        return f"AND [System.State] <> '{escape_wiql(exclude_states[0])}'"
    values = ", ".join(f"'{escape_wiql(state)}'" for state in exclude_states)
    return f"AND [System.State] NOT IN ({values})"


def query_work_item_ids_by_area(
    area_path: str,
    *,
    exact: bool = False,
    exclude_states: list[str] | None = None,
) -> list[int]:
    operator = "=" if exact else "UNDER"
    escaped = escape_wiql(area_path)
    state_clause = build_state_exclusion_clause(normalize_exclude_states(exclude_states))
    wiql = (
        "SELECT [System.Id] FROM WorkItems "
        f"WHERE [System.AreaPath] {operator} '{escaped}' "
        f"{state_clause} "
        "ORDER BY [System.Id]"
    )

    response = tfs_request(
        "POST",
        "_apis/wit/wiql",
        params={"api-version": get_api_version()},
        json_body={"query": wiql},
    )
    data = response.json()
    work_items = data.get("workItems") or []
    return [int(item["id"]) for item in work_items]


def fetch_work_items(ids: list[int]) -> list[dict[str, Any]]:
    if not ids:
        return []

    api_version = get_api_version()
    result: list[dict[str, Any]] = []

    for offset in range(0, len(ids), BATCH_SIZE):
        chunk = ids[offset : offset + BATCH_SIZE]
        response = tfs_request(
            "POST",
            "_apis/wit/workitemsbatch",
            params={"api-version": api_version},
            json_body={"ids": chunk, "$expand": "All"},
        )
        items = response.json().get("value") or []
        result.extend(items)

    result.sort(key=lambda item: item.get("id", 0))
    return result


def get_work_item(work_item_id: int) -> dict[str, Any]:
    response = tfs_request(
        "GET",
        f"_apis/wit/workitems/{work_item_id}",
        params={"$expand": "all", "api-version": get_api_version()},
    )
    return response.json()


def get_work_items_by_area(
    area_path: str,
    *,
    exact: bool = False,
    exclude_states: list[str] | None = None,
) -> dict[str, Any]:
    excluded = normalize_exclude_states(exclude_states)
    ids = query_work_item_ids_by_area(
        area_path, exact=exact, exclude_states=excluded
    )
    items = fetch_work_items(ids)
    return {
        "areaPath": area_path,
        "includeChildren": not exact,
        "excludeStates": excluded,
        "count": len(items),
        "workItems": items,
    }


def format_summary(item: dict[str, Any]) -> str:
    fields = item.get("fields", {})
    assigned = fields.get("System.AssignedTo")
    if isinstance(assigned, dict):
        assigned = assigned.get("displayName")

    lines = [
        f"ID:          {item.get('id')}",
        f"Rev:         {item.get('rev')}",
        f"Type:        {fields.get('System.WorkItemType')}",
        f"Title:       {fields.get('System.Title')}",
        f"State:       {fields.get('System.State')}",
        f"Assigned:    {assigned}",
        f"Area:        {fields.get('System.AreaPath')}",
        f"Iteration:   {fields.get('System.IterationPath')}",
        f"Created:     {fields.get('System.CreatedDate')}",
        f"Changed:     {fields.get('System.ChangedDate')}",
        f"URL:         {item.get('url')}",
    ]
    return "\n".join(lines)


def format_area_list(data: dict[str, Any]) -> str:
    excluded = data.get("excludeStates") or []
    lines = [
        f"Area:   {data['areaPath']}",
        f"Mode:   {'exact' if not data['includeChildren'] else 'under (with children)'}",
        f"Exclude states: {', '.join(excluded) if excluded else '(none)'}",
        f"Count:  {data['count']}",
        "",
    ]
    for item in data["workItems"]:
        fields = item.get("fields", {})
        lines.append(
            f"{item.get('id')}\t{fields.get('System.WorkItemType', '?')}\t"
            f"{fields.get('System.State', '?')}\t{fields.get('System.Title', '')}"
        )
    return "\n".join(lines)


def dump_json(data: Any, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def handle_errors(func: Any) -> int:
    try:
        return func()
    except requests.exceptions.SSLError as exc:
        print(
            "Ошибка SSL: сертификат TFS не доверен Python.\n"
            "Варианты в .env:\n"
            "  TFS_CA_BUNDLE=C:\\path\\to\\corporate-ca.pem  (рекомендуется)\n"
            "  TFS_VERIFY_SSL=false  (отключить проверку, только для внутренней сети)\n"
            f"\nДетали: {exc}",
            file=sys.stderr,
        )
        return 1
    except (FileNotFoundError, ValueError, requests.HTTPError) as exc:
        print(f"Ошибка: {exc}", file=sys.stderr)
        return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Получить work items из TFS / Azure DevOps"
    )
    parser.add_argument(
        "--env",
        type=Path,
        default=None,
        help="Путь к .env (по умолчанию .env рядом со скриптом)",
    )

    subparsers = parser.add_subparsers(dest="command")

    get_parser = subparsers.add_parser("get", help="Получить задачу по ID")
    get_parser.add_argument("id", type=int, help="ID work item")
    get_parser.add_argument(
        "--json",
        action="store_true",
        help="Вывести полный JSON в stdout",
    )

    area_parser = subparsers.add_parser(
        "by-area",
        help="Получить все задачи в Area (включая вложенные подпути)",
    )
    area_parser.add_argument(
        "area",
        help=r"System.AreaPath, например IResearch\KSN-AMR",
    )
    area_parser.add_argument(
        "--exact",
        action="store_true",
        help="Только точное совпадение Area, без дочерних путей",
    )
    area_parser.add_argument(
        "-o",
        "--output",
        type=Path,
        metavar="FILE",
        help="Сохранить результат в JSON-файл",
    )
    area_parser.add_argument(
        "--json",
        action="store_true",
        help="Вывести полный JSON в stdout (если не задан --output)",
    )
    area_parser.add_argument(
        "--exclude-state",
        dest="exclude_states",
        action="append",
        default=[],
        metavar="STATE",
        help=(
            "Исключить задачи в указанном статусе. "
            "Можно повторять или перечислить через запятую: "
            "--exclude-state Closed --exclude-state Removed"
        ),
    )

    return parser


def main() -> int:
    # Обратная совместимость: python get_work_item.py 12345 [--json]
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        sys.argv.insert(1, "get")

    parser = build_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    def run() -> int:
        load_config(args.env)

        if args.command == "get":
            item = get_work_item(args.id)
            if args.json:
                print(json.dumps(item, ensure_ascii=False, indent=2))
            else:
                print(format_summary(item))
            return 0

        data = get_work_items_by_area(
            args.area,
            exact=args.exact,
            exclude_states=args.exclude_states,
        )

        if args.output:
            dump_json(data, args.output)
            print(f"Сохранено {data['count']} задач в {args.output}")
            return 0

        if args.json:
            print(json.dumps(data, ensure_ascii=False, indent=2))
        else:
            print(format_area_list(data))
        return 0

    return handle_errors(run)


if __name__ == "__main__":
    sys.exit(main())
