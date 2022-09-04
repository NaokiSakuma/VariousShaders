using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

namespace Utility
{
    public class SearchUsingTagLayer : MonoBehaviour
    {
        [MenuItem("SearchUsing/TagLayer")]
        private static void FindAssets()
        {
            var myStructs = AssetDatabase
                .FindAssets("t:Prefab", new[] { "Assets" })
                .Select(AssetDatabase.GUIDToAssetPath)
                .SelectMany(path =>
                {
                    var objs = AssetDatabase.LoadAssetAtPath<GameObject>(path)
                        .GetComponentsInChildren<Transform>(true)
                        .Select(x => x.gameObject);

                    return objs.Select(x => new MyStruct { Path = path, Obj = x });
                }).ToArray();

            var tagDic = new Dictionary<string, List<string>>();
            var layerDic = new Dictionary<string, List<string>>();

            foreach (var myStruct in myStructs)
            {
                if (tagDic.ContainsKey(myStruct.Obj.tag))
                {
                    tagDic[myStruct.Obj.tag].Add(myStruct.Path);
                }
                else
                {
                    tagDic[myStruct.Obj.tag] = new List<string> { myStruct.Path };
                }

                var layerName = LayerMask.LayerToName(myStruct.Obj.layer);
                if (layerDic.ContainsKey(layerName))
                {
                    layerDic[layerName].Add(myStruct.Path);
                }
                else
                {
                    layerDic[layerName] = new List<string> { myStruct.Path };
                }
            }

            foreach (var d in tagDic)
            {
                var str = string.Join("\n", d.Value);
                Debug.Log($"tag: {d.Key}\n {str}");
            }

            foreach (var d in layerDic)
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
    }
}
