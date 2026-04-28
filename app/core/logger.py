import logging


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,  # change to DEBUG for more detail
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    )


def get_logger(name: str):
    return logging.getLogger(name)