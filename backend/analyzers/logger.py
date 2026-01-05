import logging
import sys

def setup_logger(name, level=logging.DEBUG):
    """设置日志记录器"""
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # 清除已有的处理器
    logger.handlers.clear()
    
    # 控制台处理器 - 使用 stderr 确保立即输出
    console_handler = logging.StreamHandler(sys.stderr)
    console_handler.setLevel(level)
    
    # 简单格式
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%H:%M:%S'
    )
    console_handler.setFormatter(formatter)
    
    logger.addHandler(console_handler)
    logger.propagate = False  # 防止传播到根日志器
    
    return logger