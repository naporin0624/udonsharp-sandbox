
using UdonSharp;
using UnityEngine;

public class Decrement : UdonSharpBehaviour
{
    [SerializeField]
    private Store store;


    public void Pressed()
    {
        store.Decrement();
    }
}
