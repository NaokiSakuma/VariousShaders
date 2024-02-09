using Unity.Collections;
using Unity.Jobs;
using UnityEngine;

namespace SimpleJobSystem
{
    public class ParallelLogJobSystem : MonoBehaviour
    {
        private struct MyParallelJob : IJobParallelFor
        {
            [ReadOnly] public NativeArray<float> a;
            [ReadOnly] public NativeArray<float> b;

            public NativeArray<float> result;

            public void Execute(int index)
            {
                result[index] = a[index] + b[index];
            }
        }

        private void Update()
        {
            var count = 2;
            var a = new NativeArray<float>(count, Allocator.TempJob);
            var b = new NativeArray<float>(count, Allocator.TempJob);
            var result = new NativeArray<float>(count, Allocator.TempJob);

            a[0] = 1.1f;
            b[0] = 2.2f;
            a[1] = 3.3f;
            b[1] = 4.4f;

            var job = new MyParallelJob
            {
                a = a,
                b = b,
                result = result
            };

            var handle = job.Schedule(result.Length, 1);
            JobHandle.ScheduleBatchedJobs();

            handle.Complete();

            Debug.Log($"{result[0]} , {result[1]}");

            a.Dispose();
            b.Dispose();
            result.Dispose();
        }
    }
}