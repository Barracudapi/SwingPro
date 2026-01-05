import numpy as np
import csv
import math
import matplotlib.pyplot as plt


# ============================================================
# 读取单 IMU CSV
# ============================================================
def load_single_imu_csv(csv_path):
    acc_data = []
    gyro_data = []

    with open(csv_path, mode="r", newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)  # 跳过表头

        for row in reader:
            if not row:
                continue

            filtered_row = [item.strip() for item in row if item.strip()]

            # acc: columns 3,4,5
            acc = [filtered_row[3], filtered_row[4], filtered_row[5]]
            # gyro: columns 6,7,8
            gyro = [filtered_row[6], filtered_row[7], filtered_row[8]]

            acc_data.append(acc)
            gyro_data.append(gyro)

    return np.array(acc_data, float), np.array(gyro_data, float)


# ============================================================
# 击球检测（角速度变化 + 符号翻转）
# ============================================================
def detect_stroke_timestamps(gyro, acc, threshold=300):
    gyro = np.array(gyro, float)
    acc = np.array(acc, float)

    gyro_diff = np.abs(np.diff(gyro, axis=0))
    gyro_sign_change = np.diff(np.sign(gyro), axis=0)
    acc_sign_change = np.diff(np.sign(acc), axis=0)

    stroke_indices = []

    for i in range(len(gyro_diff)):
        if np.any(gyro_diff[i] > threshold):

            start = max(0, i - 3)
            end = min(len(gyro_sign_change), i + 3)

            has_change = (
                np.any(np.abs(gyro_sign_change[start:end]) > 0) and
                np.any(np.abs(acc_sign_change[start:end]) > 0)
            )

            if has_change:
                stroke_indices.append(i + 1)

    return stroke_indices


# ============================================================
# 合并过滤时间戳（避免重复）
# ============================================================
def filter_timestamps(timestamps, min_gap=75):
    if not timestamps:
        return []
    filtered = [timestamps[0]]
    for i in range(1, len(timestamps)):
        if timestamps[i] - timestamps[i - 1] >= min_gap:
            filtered.append(timestamps[i])
    return filtered


# ============================================================
# 提取击球窗口切片
# ============================================================
def extract_stroke_slices(acc, gyro, timestamps, window_size=200, plot=True):
    acc_slices = []
    gyro_slices = []
    half = window_size // 2

    for t in timestamps:
        start = max(t - half, 0)
        end = min(t + half, len(acc))

        if end - start != window_size:
            continue

        acc_slice = acc[start:end]
        gyro_slice = gyro[start:end]

        if plot:
            ax = np.arange(window_size)
            plt.figure(figsize=(12, 5))

            plt.subplot(1, 2, 1)
            plt.plot(ax, acc_slice[:, 0], label="ax")
            plt.plot(ax, acc_slice[:, 1], label="ay")
            plt.plot(ax, acc_slice[:, 2], label="az")
            plt.legend()
            plt.title("Acceleration Slice")

            plt.subplot(1, 2, 2)
            plt.plot(ax, gyro_slice[:, 0], label="gx")
            plt.plot(ax, gyro_slice[:, 1], label="gy")
            plt.plot(ax, gyro_slice[:, 2], label="gz")
            plt.legend()
            plt.title("Gyro Slice")

            plt.show()

        acc_slices.append(acc_slice)
        gyro_slices.append(gyro_slice)

    return acc_slices, gyro_slices


# ============================================================
# 统一入口方法，可直接在外部调用
# ============================================================
def process_single_imu_csv(csv_path,
                           threshold=300,
                           slice_len=200,
                           plot=True):
    """
    输入：CSV 文件
    输出：击球时间戳 + 每次击球的 acc/gyro 切片
    """

    acc, gyro = load_single_imu_csv(csv_path)

    timestamps = detect_stroke_timestamps(gyro, acc, threshold)
    timestamps = filter_timestamps(timestamps)

    acc_slices, gyro_slices = extract_stroke_slices(
        acc, gyro, timestamps, slice_len, plot
    )

    return {
        "timestamps": timestamps,
        "acc_slices": acc_slices,
        "gyro_slices": gyro_slices
    }


# 直接运行脚本时
if __name__ == "__main__":
    result = process_single_imu_csv("example.csv", plot=False)
    print("Detected strokes:", result["timestamps"])
