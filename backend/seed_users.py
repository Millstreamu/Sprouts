from __future__ import annotations

import argparse

from .user_store import UserStore


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create/update an auth user")
    parser.add_argument("--db", default="./data/auth.db", help="Path to sqlite db")
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--role", required=True, choices=["owner", "manager", "staff", "read_only"])
    parser.add_argument("--inactive", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    store = UserStore(args.db)
    store.init_db()
    store.upsert_user(
        username=args.username,
        password=args.password,
        role=args.role,
        is_active=not args.inactive,
    )
    print(f"User '{args.username}' created/updated with role '{args.role}'.")


if __name__ == "__main__":
    main()
