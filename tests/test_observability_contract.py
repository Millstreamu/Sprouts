from pathlib import Path

OBS_PATH = Path('sprouts/scripts/backend/Observability.gd')


def test_observability_script_exists():
    assert OBS_PATH.exists(), 'Observability singleton script must exist'


def test_error_response_contract_present():
    text = OBS_PATH.read_text()
    assert 'func error_response' in text
    assert '"ok": false' in text
    assert '"request_id"' in text


def test_sensitive_markers_are_redacted():
    text = OBS_PATH.read_text().lower()
    for marker in ['password', 'secret', 'token', 'auth', 'cookie']:
        assert marker in text
    assert '[redacted]' in text
