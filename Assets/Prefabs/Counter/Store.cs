using UdonSharp;
using VRC.SDKBase;

public class Store : Notifyer
{
    [UdonSynced(UdonSyncMode.None)]
    private int _count = 0;

    public int count
    {
        get
        {
            return _count;
        }
    }

    private void transferOwner()
    {
        var player = Networking.LocalPlayer;
        Networking.SetOwner(player, gameObject);
    }

    private void sync()
    {
        var player = Networking.LocalPlayer;
        if (player.IsOwner(gameObject))
        {
            RequestSerialization();
            Notify();
        }
    }

    public override void OnDeserialization()
    {
        Notify();
    }
    public override void OnPlayerJoined(VRCPlayerApi player)
    {
        RequestSerialization();
    }

    public void Increment()
    {
        transferOwner();
        _count++;
        sync();
    }

    public void Decrement()
    {
        transferOwner();
        _count--;
        sync();
    }
}