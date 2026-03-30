# 实现冒泡排序算法
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                # 交换两个元素
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr

# 测试代码
if __name__ == "__main__":
    test_arr = [64, 34, 25, 12, 22, 11, 90]
    bubble_sort(test_arr)
    print("排序后的数组：", test_arr)