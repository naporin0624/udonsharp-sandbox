
using UdonSharp;
using UnityEngine;

public class Observer : UdonSharpBehaviour
{
    [SerializeField]
    private Notifyer notifyer;

    void Start()
    {
        notifyer.Register(this);
    }

    public virtual void OnNotify()
    {
        Debug.LogError("OnNotify() がオーバーライドされていません。派生クラスで実装してください。");
    }
}
