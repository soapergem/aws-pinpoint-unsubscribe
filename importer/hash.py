import hashlib

ALPHABET = "23456789abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"


def to_hash(text):
    hex_value = hashlib.sha256(text.encode("utf-8")).hexdigest()[-14:]
    int_value = int(hex_value, 16)
    arr = []
    base = len(ALPHABET)
    while int_value:
        int_value, rem = divmod(int_value, base)
        arr.append(ALPHABET[rem])
    arr.reverse()
    return "".join(arr)
