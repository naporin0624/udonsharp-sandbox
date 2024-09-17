using UdonSharp;
using UnityEngine;

public class Notifyer : UdonSharpBehaviour
{
    [SerializeField]
    private UdonSharpBehaviour[] observers;

    public void Register(UdonSharpBehaviour observer)
    {
        for (int i = 0; i < observers.Length; i++)
        {
            if (observers[i] == observer)
            {
                return;
            }
        }

        for (int i = 0; i < observers.Length; i++)
        {
            if (observers[i] == null)
            {
                observers[i] = observer;
                return;
            }
        }
    }

    protected void Notify()
    {
        foreach (UdonSharpBehaviour observer in observers)
        {
            if (observer != null)
            {
                observer.SendCustomEvent("OnNotify");
            }
        }
    }
}

