using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

namespace Utility
{
    public class SearchUsingSortingLayer : MonoBehaviour
    {
        [MenuItem("SearchUsing/SortingLayer")]
        private static void FindAssets()
        {
            var myStructs = AssetDatabase
                .FindAssets("t:Prefab", new[] { "Assets" })
                .Select(AssetDatabase.GUIDToAssetPath)
                .SelectMany(path =>
                {
                    var objs = AssetDatabase.LoadAssetAtPath<GameObject>(path)
                        .GetComponentsInChildren<Transform>(true)
                        .Select(x => x.gameObject)
                        .ToArray();

                    return objs.Select(x => new MyStruct { Path = path, Obj = x });
                }).ToArray();

            var sprites = myStructs
                .Where(x => x.Obj.GetComponent<SpriteRenderer>() != null)
                .Select(x => new SpriteRendererParam { Path = x.Path, Obj = x.Obj.GetComponent<SpriteRenderer>() });

            var canvases = myStructs
                .Where(x => x.Obj.GetComponent<Canvas>() != null)
                .Select(x => new CanvasParam { Path = x.Path, Obj = x.Obj.GetComponent<Canvas>() });

            var particles = myStructs
                .Where(x => x.Obj.GetComponent<ParticleSystemRenderer>() != null)
                .Select(x => new ParticleSystemRendererParam { Path = x.Path, Obj = x.Obj.GetComponent<ParticleSystemRenderer>() });

            var sortingLayerDic = new Dictionary<string, List<string>>();

            foreach (var sprite in sprites)
            {
                if (sortingLayerDic.ContainsKey(sprite.Obj.sortingLayerName))
                {
                    sortingLayerDic[sprite.Obj.sortingLayerName].Add(sprite.Path);
                }
                else
                {
                    sortingLayerDic[sprite.Obj.sortingLayerName] = new List<string> { sprite.Path };
                }
            }

            foreach (var canvas in canvases)
            {
                if (sortingLayerDic.ContainsKey(canvas.Obj.sortingLayerName))
                {
                    sortingLayerDic[canvas.Obj.sortingLayerName].Add(canvas.Path);
                }
                else
                {
                    sortingLayerDic[canvas.Obj.sortingLayerName] = new List<string> { canvas.Path };
                }
            }


            foreach (var particle in particles)
            {
                if (sortingLayerDic.ContainsKey(particle.Obj.sortingLayerName))
                {
                    sortingLayerDic[particle.Obj.sortingLayerName].Add(particle.Path);
                }
                else
                {
                    sortingLayerDic[particle.Obj.sortingLayerName] = new List<string> { particle.Path };
                }
            }

            foreach (var d in sortingLayerDic)
            {
                var str = string.Join("\n", d.Value);
                Debug.Log($"layer: {d.Key}\n {str}");
            }
        }

        private struct MyStruct
        {
            public string Path;
            public GameObject Obj;
        }

        private struct SpriteRendererParam
        {
            public string Path;
            public SpriteRenderer Obj;
        }

        private struct CanvasParam
        {
            public string Path;
            public Canvas Obj;
        }

        private struct ParticleSystemRendererParam
        {
            public string Path;
            public ParticleSystemRenderer Obj;
        }
    }
}
