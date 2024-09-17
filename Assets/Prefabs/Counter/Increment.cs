using UdonSharp;
using UnityEngine;

public class Increment : UdonSharpBehaviour {
    [SerializeField]
    private Store store;

    public void Pressed()
    {
        store.Increment();
    }
}
