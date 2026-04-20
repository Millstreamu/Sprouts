from psycopg import connect
from psycopg.errors import OperationalError


def can_connect(database_url: str) -> bool:
    try:
        with connect(database_url, connect_timeout=2) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return True
    except OperationalError:
        return False
