using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Jobs;
using UnityEngine.Rendering;

namespace SimpleJobSystem
{
    public class Hoge : MonoBehaviour
    {
        private struct RotateJob : IJobParallelForTransform
        {
            private readonly float offset;
            private const float height = 1f;
            private const float per = 128f;

            public RotateJob(float offset)
            {
                this.offset = offset;
            }

            public void Execute(int index, TransformAccess transform)
            {
                var pos = transform.localPosition;
                var x = pos.x * 0.2f + offset;
                var z = pos.z * 0.2f + offset;
                // Vectorじゃダメ？
                var noisePos = new float2(x, z);
                pos.y = noise.psrnoise(noisePos, new float2(per, per)) * height;

                transform.localPosition = pos;
            }
        }
        
        
        [SerializeField]
        private Transform parent;

        private TransformAccessArray transforms;
        private JobHandle jobHandle;

        private void Awake()
        {
            // Cubeをたくさん敷き詰める
            var size = 35;
            var list = new List<Transform>();

            for (var z = -size; z <= size; z++) {
                for (var x = -size; x <= size; x++)
                {
                    var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    cube.transform.position = new Vector3 (x * 1.1f, 0, z * 1.1f);
                    list.Add(cube.transform);
                }
            }
            Debug.Log("Cube Count : " + list.Count);

            // https://docs.unity3d.com/ja/2018.4/ScriptReference/Jobs.TransformAccessArray.html
            transforms = new TransformAccessArray(list.ToArray());
        }

        private void Update()
        {
            jobHandle.Complete();
            jobHandle = new RotateJob(Time.timeSinceLevelLoad).Schedule(transforms, jobHandle);
            JobHandle.ScheduleBatchedJobs();
        }

        private void OnDestroy()
        {
            transforms.Dispose();
        }
    }
}
