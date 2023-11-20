using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Jobs;
using UnityEngine;

public class JobOrder : MonoBehaviour
{
    private struct MyJob1 : IJob
    {
        public NativeArray<float> values;

        public void Execute()
        {
            values[0] += 1;
        }
    }

    private struct MyJob2 : IJob
    {
        public NativeArray<float> values;

        public void Execute()
        {
            values[0] *= values[0];
        }
    }

    private void Update()
    {
        var result = new NativeArray<float>(1, Allocator.TempJob);
        result[0] = 1;

        var myJob1 = new MyJob1
        {
            values = result
        };

        var myJob2 = new MyJob2
        {
            values = result
        };

        var firstJobHandle = myJob1.Schedule();
        var secondJobHandle = myJob2.Schedule(firstJobHandle);

        secondJobHandle.Complete();

        Debug.Log(result[0]);

        result.Dispose();
    }
}
