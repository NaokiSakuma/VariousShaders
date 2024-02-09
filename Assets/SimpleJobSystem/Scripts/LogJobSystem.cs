using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;

namespace SimpleJobSystem
{
    public class LogJobSystem : MonoBehaviour
    {
        private struct MyJob : IJob
        {
            public float a;
            public float b;

            public NativeArray<float> result;

            public void Execute()
            {
                result[0] = a + b;
            }
        }

        private void Update()
        {
            var resultArray = new NativeArray<float>(1, Allocator.TempJob);

            var myJob = new MyJob
            {
                a = 5,
                b = 10,
                result = resultArray
            };

            var handle = myJob.Schedule();
            JobHandle.ScheduleBatchedJobs();

            Thread.Sleep(10);
            handle.Complete();

            Debug.Log($"resultArray[0] = {resultArray[0]}");

            resultArray.Dispose();
        }
    }
}
